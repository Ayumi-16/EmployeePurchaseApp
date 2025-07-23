import Foundation
@testable import EmployeePurchaseApp

/// Mock implementation of CSVService for testing purposes
final class MockCSVService: CSVService {
    
    // MARK: - Mock Properties
    
    var employees: [Employee] = []
    var purchases: [Purchase] = []
    var shouldFailLoadEmployees = false
    var shouldFailAppendPurchase = false
    var mockError: AppError?
    var loadEmployeesCallCount = 0
    var appendPurchaseCallCount = 0
    var fileExistsCallCount = 0
    
    // MARK: - Mock File System
    
    private var mockFiles: [String: String] = [:]
    private var mockDocumentsURL = URL(fileURLWithPath: "/tmp/test_documents")
    
    // MARK: - Initialization
    
    override init(fileManager: FileManager = .default) {
        super.init(fileManager: fileManager)
        setupDefaultTestData()
    }
    
    // MARK: - Mock Implementation
    
    override func documentsURL() -> URL {
        return mockDocumentsURL
    }
    
    override func fileExists(named fileName: String) -> Bool {
        fileExistsCallCount += 1
        return mockFiles.keys.contains(fileName)
    }
    
    override func loadEmployees() async throws -> [Employee] {
        loadEmployeesCallCount += 1
        
        if let error = mockError {
            throw error
        }
        
        if shouldFailLoadEmployees {
            throw AppError.csvImportFailed
        }
        
        return employees
    }
    
    override func appendPurchase(_ purchase: Purchase) async throws {
        appendPurchaseCallCount += 1
        
        if let error = mockError {
            throw error
        }
        
        if shouldFailAppendPurchase {
            throw AppError.purchaseFailed
        }
        
        purchases.append(purchase)
        
        // Simulate file writing
        let csvRow = formatPurchaseAsCSVRow(purchase)
        if let existingContent = mockFiles["purchases.csv"] {
            mockFiles["purchases.csv"] = existingContent + csvRow
        } else {
            let header = "purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes\n"
            mockFiles["purchases.csv"] = header + csvRow
        }
    }
    
    // MARK: - Mock Configuration Methods
    
    func setEmployees(_ employees: [Employee]) {
        self.employees = employees
        
        // Create mock CSV content
        var csvContent = "id,name\n"
        for employee in employees {
            csvContent += "\(employee.id),\(employee.name)\n"
        }
        mockFiles["employees.csv"] = csvContent
    }
    
    func setMockError(_ error: AppError?) {
        mockError = error
    }
    
    func setShouldFailLoadEmployees(_ shouldFail: Bool) {
        shouldFailLoadEmployees = shouldFail
    }
    
    func setShouldFailAppendPurchase(_ shouldFail: Bool) {
        shouldFailAppendPurchase = shouldFail
    }
    
    func setMockDocumentsURL(_ url: URL) {
        mockDocumentsURL = url
    }
    
    func setMockFileContent(fileName: String, content: String) {
        mockFiles[fileName] = content
    }
    
    func getMockFileContent(fileName: String) -> String? {
        return mockFiles[fileName]
    }
    
    func reset() {
        employees = []
        purchases = []
        shouldFailLoadEmployees = false
        shouldFailAppendPurchase = false
        mockError = nil
        loadEmployeesCallCount = 0
        appendPurchaseCallCount = 0
        fileExistsCallCount = 0
        mockFiles = [:]
        setupDefaultTestData()
    }
    
    // MARK: - Test Helper Methods
    
    func simulateFileNotFound() {
        mockFiles.removeValue(forKey: "employees.csv")
        mockError = AppError.fileNotFound
    }
    
    func simulateCSVImportFailed() {
        shouldFailLoadEmployees = true
        mockError = AppError.csvImportFailed
    }
    
    func simulatePurchaseFailed() {
        shouldFailAppendPurchase = true
        mockError = AppError.purchaseFailed
    }
    
    func simulateValidEmployeeCSV() {
        let csvContent = """
        id,name
        EMP001,田中太郎
        EMP002,佐藤花子
        EMP003,鈴木次郎
        TEST001,テスト太郎
        ADMIN001,管理者
        """
        mockFiles["employees.csv"] = csvContent
        employees = CSVTestDataFactory.createTestEmployees()
    }
    
    func simulateInvalidEmployeeCSV() {
        let csvContent = """
        id,name
        EMP001
        EMP002,佐藤花子,extra_column
        """
        mockFiles["employees.csv"] = csvContent
        shouldFailLoadEmployees = true
    }
    
    func simulateEmptyEmployeeCSV() {
        let csvContent = "id,name"
        mockFiles["employees.csv"] = csvContent
        shouldFailLoadEmployees = true
    }
    
    func simulateExistingPurchasesFile() {
        let csvContent = """
        purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes
        2025-01-01 10:00:00,EMP001,田中太郎,PROD001,テストシューズ,shoes,M,1,1000,1000,cash,success,TestBrand,テストノート
        """
        mockFiles["purchases.csv"] = csvContent
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultTestData() {
        employees = CSVTestDataFactory.createTestEmployees()
        simulateValidEmployeeCSV()
    }
    
    private func formatPurchaseAsCSVRow(_ purchase: Purchase) -> String {
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
        return rowComponents.joined(separator: ",") + "\n"
    }
}

// MARK: - Mock FileManager

class MockFileManager: FileManager {
    var files: [String: String] = [:]
    var shouldFailWrite = false
    var documentsDirectory: URL
    var fileExistsCallCount = 0
    var urlsCallCount = 0
    
    override init() {
        self.documentsDirectory = URL(fileURLWithPath: "/tmp/test_documents")
        super.init()
    }
    
    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        urlsCallCount += 1
        return [documentsDirectory]
    }
    
    override func fileExists(atPath path: String) -> Bool {
        fileExistsCallCount += 1
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        return files.keys.contains(fileName)
    }
    
    func setFileContent(fileName: String, content: String) {
        files[fileName] = content
    }
    
    func getFileContent(fileName: String) -> String? {
        return files[fileName]
    }
    
    func setDocumentsDirectory(_ url: URL) {
        documentsDirectory = url
    }
    
    func reset() {
        files = [:]
        shouldFailWrite = false
        fileExistsCallCount = 0
        urlsCallCount = 0
    }
    
    func simulateWriteFailure() {
        shouldFailWrite = true
    }
}

// MARK: - CSV Test Data Factory

struct CSVTestDataFactory {
    
    static func createTestEmployees() -> [Employee] {
        return [
            Employee(id: "EMP001", name: "田中太郎"),
            Employee(id: "EMP002", name: "佐藤花子"),
            Employee(id: "EMP003", name: "鈴木次郎"),
            Employee(id: "TEST001", name: "テスト太郎"),
            Employee(id: "ADMIN001", name: "管理者")
        ]
    }
    
    static func createTestPurchases() -> [Purchase] {
        return [
            Purchase(
                purchaseDate: Date(),
                employeeId: "EMP001",
                employeeName: "田中太郎",
                productId: "PROD001",
                productName: "テストシューズ",
                category: "shoes",
                size: "M",
                quantity: 1,
                unitPrice: 1000,
                paymentMethod: .cash,
                status: .success,
                brand: "TestBrand",
                notes: "テストノート"
            ),
            Purchase(
                purchaseDate: Date(),
                employeeId: "EMP002",
                employeeName: "佐藤花子",
                productId: "PROD002",
                productName: "テストバッグ",
                category: "accessories",
                size: "F",
                quantity: 2,
                unitPrice: 2000,
                paymentMethod: .payrollDeduction,
                status: .success,
                brand: "TestBrand",
                notes: "給与天引きテスト"
            )
        ]
    }
    
    static func createValidEmployeeCSV() -> String {
        return """
        id,name
        EMP001,田中太郎
        EMP002,佐藤花子
        EMP003,鈴木次郎
        TEST001,テスト太郎
        ADMIN001,管理者
        """
    }
    
    static func createInvalidEmployeeCSV() -> String {
        return """
        id,name
        EMP001
        EMP002,佐藤花子,extra_column
        """
    }
    
    static func createEmptyEmployeeCSV() -> String {
        return "id,name"
    }
    
    static func createEmployeeCSVWithEmptyLines() -> String {
        return """
        id,name
        EMP001,田中太郎
        
        EMP002,佐藤花子
        
        EMP003,鈴木次郎
        """
    }
    
    static func createPurchasesCSVHeader() -> String {
        return "purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes"
    }
    
    static func createValidPurchasesCSV() -> String {
        let header = createPurchasesCSVHeader()
        let rows = """
        2025-01-01 10:00:00,EMP001,田中太郎,PROD001,テストシューズ,shoes,M,1,1000,1000,cash,success,TestBrand,テストノート
        2025-01-02 14:30:00,EMP002,佐藤花子,PROD002,テストバッグ,accessories,F,2,2000,4000,payrollDeduction,success,TestBrand,給与天引きテスト
        """
        return header + "\n" + rows
    }
}