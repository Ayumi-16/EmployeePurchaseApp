import Foundation

/// Handles CSV file operations such as reading employee data and writing purchase history.
open class CSVService {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Returns the URL for the application's Documents directory.
    public func documentsURL() -> URL {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentURL = urls.first else {
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }
        return documentURL
    }

    /// Returns a file URL within the Documents directory.
    private func fileURL(fileName: String) -> URL {
        let url = documentsURL().appendingPathComponent(fileName)
        return url
    }

    /// Checks if a file exists in the Documents directory.
    public func fileExists(named fileName: String) -> Bool {
        let exists = fileManager.fileExists(atPath: fileURL(fileName: fileName).path)
        return exists
    }

    /// Loads employee master data from `employees.csv`.
    public func loadEmployees() async throws -> [Employee] {
        let fileName = "employees.csv"
        guard fileExists(named: fileName) else {
            throw AppError.fileNotFound
        }

        let url = fileURL(fileName: fileName)

        return try await Task.detached(priority: .utility) { () -> [Employee] in
            let csvText = try String(contentsOf: url, encoding: .utf8)
            let lines = csvText.components(separatedBy: .newlines)
            guard lines.count > 1 else {
                throw AppError.csvImportFailed
            }

            var employees: [Employee] = []
            for index in 1..<lines.count {
                let line = lines[index]
                if line.isEmpty {
                    continue
                }

                let columns = line.components(separatedBy: ",")
                guard columns.count >= 2 else {
                    throw AppError.csvImportFailed
                }

                let id = columns[0]
                let name = columns[1]
                let employee = Employee(id: id, name: name)
                employees.append(employee)
            }
            return employees
        }.value
    }

    /// Appends a purchase record to `purchases.csv`.
    public func appendPurchase(_ purchase: Purchase) async throws {
        let url = fileURL(fileName: "purchases.csv")

        try await Task.detached(priority: .utility) {
            if !self.fileExists(named: "purchases.csv") {
                let header = "purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes\n"
                try header.write(to: url, atomically: true, encoding: .utf8)
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            let rowComponents: [String] = [
                formatter.string(from: purchase.purchaseDate),
                purchase.employeeId,
                purchase.employeeName,
                purchase.productId,
                purchase.productName,
                purchase.category,
                purchase.size,
                String(purchase.quantity),
                String(purchase.unitPrice),
                String(purchase.totalAmount),
                purchase.paymentMethod.rawValue,
                purchase.status.rawValue,
                purchase.brand,
                purchase.notes
            ]
            let row = rowComponents.joined(separator: ",") + "\n"
            guard let data = row.data(using: .utf8) else { throw AppError.purchaseFailed }

            if let handle = FileHandle(forWritingAtPath: url.path) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                throw AppError.purchaseFailed
            }
        }.value
    }
}
