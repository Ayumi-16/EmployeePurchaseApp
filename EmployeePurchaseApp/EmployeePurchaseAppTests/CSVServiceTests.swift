import Testing
import Foundation
@testable import EmployeePurchaseApp

struct CSVServiceTests {
    
    // MARK: - Test Data
    
    private func createTestEmployee() -> Employee {
        Employee(id: "TEST001", name: "テスト太郎")
    }
    
    private func createTestPurchase() -> Purchase {
        Purchase(
            purchaseDate: Date(),
            employeeId: "TEST001",
            employeeName: "テスト太郎",
            productId: "PROD001",
            productName: "テストシューズ",
            category: "shoes",
            size: "M",
            quantity: 2,
            unitPrice: 1000,
            paymentMethod: .cash,
            status: .success,
            brand: "TestBrand",
            notes: "テストノート"
        )
    }
    
    private func createValidEmployeeCSV() -> String {
        """
        id,name
        EMP001,田中太郎
        EMP002,佐藤花子
        EMP003,鈴木次郎
        """
    }
    
    private func createInvalidEmployeeCSV() -> String {
        """
        id,name
        EMP001
        EMP002,佐藤花子,extra_column
        """
    }
    
    // MARK: - Mock FileManager
    
    class MockFileManager: FileManager {
        var files: [String: String] = [:]
        var shouldFailWrite = false
        var documentsDirectory: URL
        
        override init() {
            self.documentsDirectory = URL(fileURLWithPath: "/tmp/test_documents")
            super.init()
        }
        
        override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
            return [documentsDirectory]
        }
        
        override func fileExists(atPath path: String) -> Bool {
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            return files.keys.contains(fileName)
        }
        
        func setFileContent(fileName: String, content: String) {
            files[fileName] = content
        }
        
        func getFileContent(fileName: String) -> String? {
            return files[fileName]
        }
    }
    
    // MARK: - Helper Methods
    
    private func createCSVService(with mockFileManager: MockFileManager) -> CSVService {
        return CSVService(fileManager: mockFileManager)
    }
    
    // MARK: - documentsURL Tests
    
    @Test func documentsURL_returnsCorrectURL() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        let url = csvService.documentsURL()
        
        #expect(url == mockFileManager.documentsDirectory)
    }
    
    // MARK: - fileExists Tests
    
    @Test func fileExists_whenFileExists_returnsTrue() async throws {
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "test.csv", content: "test content")
        let csvService = createCSVService(with: mockFileManager)
        
        let exists = csvService.fileExists(named: "test.csv")
        
        #expect(exists == true)
    }
    
    @Test func fileExists_whenFileDoesNotExist_returnsFalse() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        let exists = csvService.fileExists(named: "nonexistent.csv")
        
        #expect(exists == false)
    }
    
    // MARK: - loadEmployees Tests
    
    @Test func loadEmployees_withValidCSV_returnsEmployees() async throws {
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "employees.csv", content: createValidEmployeeCSV())
        let csvService = createCSVService(with: mockFileManager)
        
        let employees = try await csvService.loadEmployees()
        
        #expect(employees.count == 3)
        #expect(employees[0].id == "EMP001")
        #expect(employees[0].name == "田中太郎")
        #expect(employees[1].id == "EMP002")
        #expect(employees[1].name == "佐藤花子")
        #expect(employees[2].id == "EMP003")
        #expect(employees[2].name == "鈴木次郎")
    }
    
    @Test func loadEmployees_withEmptyLines_skipsEmptyLines() async throws {
        let csvWithEmptyLines = """
        id,name
        EMP001,田中太郎
        
        EMP002,佐藤花子
        
        """
        
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "employees.csv", content: csvWithEmptyLines)
        let csvService = createCSVService(with: mockFileManager)
        
        let employees = try await csvService.loadEmployees()
        
        #expect(employees.count == 2)
        #expect(employees[0].id == "EMP001")
        #expect(employees[1].id == "EMP002")
    }
    
    @Test func loadEmployees_whenFileNotFound_throwsFileNotFound() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        await #expect(throws: AppError.fileNotFound) {
            try await csvService.loadEmployees()
        }
    }
    
    @Test func loadEmployees_withInvalidCSV_throwsCSVImportFailed() async throws {
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "employees.csv", content: createInvalidEmployeeCSV())
        let csvService = createCSVService(with: mockFileManager)
        
        await #expect(throws: AppError.csvImportFailed) {
            try await csvService.loadEmployees()
        }
    }
    
    @Test func loadEmployees_withOnlyHeader_throwsCSVImportFailed() async throws {
        let headerOnlyCSV = "id,name"
        
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "employees.csv", content: headerOnlyCSV)
        let csvService = createCSVService(with: mockFileManager)
        
        await #expect(throws: AppError.csvImportFailed) {
            try await csvService.loadEmployees()
        }
    }
    
    @Test func loadEmployees_withMalformedColumns_throwsCSVImportFailed() async throws {
        let malformedCSV = """
        id,name
        EMP001
        EMP002,佐藤花子
        """
        
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "employees.csv", content: malformedCSV)
        let csvService = createCSVService(with: mockFileManager)
        
        await #expect(throws: AppError.csvImportFailed) {
            try await csvService.loadEmployees()
        }
    }
    
    // MARK: - appendPurchase Tests
    
    @Test func appendPurchase_createsFileWithHeaderWhenNotExists() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        let purchase = createTestPurchase()
        
        try await csvService.appendPurchase(purchase)
        
        let content = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(content != nil)
        #expect(content!.contains("purchase_date,employee_id,employee_name"))
        #expect(content!.contains("TEST001"))
        #expect(content!.contains("テスト太郎"))
        #expect(content!.contains("PROD001"))
    }
    
    @Test func appendPurchase_appendsToExistingFile() async throws {
        let existingContent = """
        purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes
        2025-01-01 10:00:00,EMP001,既存太郎,PROD999,既存商品,shoes,L,1,500,500,cash,success,ExistingBrand,既存ノート
        """
        
        let mockFileManager = MockFileManager()
        mockFileManager.setFileContent(fileName: "purchases.csv", content: existingContent)
        let csvService = createCSVService(with: mockFileManager)
        let purchase = createTestPurchase()
        
        try await csvService.appendPurchase(purchase)
        
        let content = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(content != nil)
        #expect(content!.contains("既存太郎"))  // Existing data should remain
        #expect(content!.contains("テスト太郎"))  // New data should be added
    }
    
    @Test func appendPurchase_formatsDateCorrectly() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        // Create purchase with specific date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let testDate = dateFormatter.date(from: "2025-07-22 15:30:45")!
        
        let purchase = Purchase(
            purchaseDate: testDate,
            employeeId: "TEST001",
            employeeName: "テスト太郎",
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
        )
        
        try await csvService.appendPurchase(purchase)
        
        let content = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(content != nil)
        #expect(content!.contains("2025-07-22 15:30:45"))
    }
    
    @Test func appendPurchase_handlesPaymentMethodsCorrectly() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        // Test cash payment
        let cashPurchase = Purchase(
            purchaseDate: Date(),
            employeeId: "TEST001",
            employeeName: "テスト太郎",
            productId: "PROD001",
            productName: "テストシューズ",
            category: "shoes",
            size: "M",
            quantity: 1,
            unitPrice: 1000,
            paymentMethod: .cash,
            status: .success,
            brand: "TestBrand",
            notes: "現金テスト"
        )
        
        try await csvService.appendPurchase(cashPurchase)
        
        let content = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(content != nil)
        #expect(content!.contains("cash"))
        
        // Test payroll deduction
        let payrollPurchase = Purchase(
            purchaseDate: Date(),
            employeeId: "TEST002",
            employeeName: "テスト花子",
            productId: "PROD002",
            productName: "テストバッグ",
            category: "accessories",
            size: "F",
            quantity: 1,
            unitPrice: 2000,
            paymentMethod: .payrollDeduction,
            status: .success,
            brand: "TestBrand",
            notes: "給与天引きテスト"
        )
        
        try await csvService.appendPurchase(payrollPurchase)
        
        let updatedContent = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(updatedContent != nil)
        #expect(updatedContent!.contains("payrollDeduction"))
    }
    
    @Test func appendPurchase_handlesStatusCorrectly() async throws {
        let mockFileManager = MockFileManager()
        let csvService = createCSVService(with: mockFileManager)
        
        // Test success status
        let successPurchase = Purchase(
            purchaseDate: Date(),
            employeeId: "TEST001",
            employeeName: "テスト太郎",
            productId: "PROD001",
            productName: "テストシューズ",
            category: "shoes",
            size: "M",
            quantity: 1,
            unitPrice: 1000,
            paymentMethod: .cash,
            status: .success,
            brand: "TestBrand",
            notes: "成功テスト"
        )
        
        try await csvService.appendPurchase(successPurchase)
        
        let content = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(content != nil)
        #expect(content!.contains("success"))
        
        // Test failure status
        let failurePurchase = Purchase(
            purchaseDate: Date(),
            employeeId: "TEST002",
            employeeName: "テスト花子",
            productId: "PROD002",
            productName: "テストバッグ",
            category: "accessories",
            size: "F",
            quantity: 1,
            unitPrice: 2000,
            paymentMethod: .cash,
            status: .failure,
            brand: "TestBrand",
            notes: "失敗テスト"
        )
        
        try await csvService.appendPurchase(failurePurchase)
        
        let updatedContent = mockFileManager.getFileContent(fileName: "purchases.csv")
        #expect(updatedContent != nil)
        #expect(updatedContent!.contains("failure"))
    }
}

// MARK: - Custom String Extension for Testing

extension String {
    func write(to url: URL, atomically: Bool, encoding: String.Encoding) throws {
        // Mock implementation for testing
        if let mockFileManager = FileManager.default as? CSVServiceTests.MockFileManager {
            let fileName = url.lastPathComponent
            mockFileManager.setFileContent(fileName: fileName, content: self)
        }
    }
}

// MARK: - FileHandle Mock for Testing

extension FileHandle {
    convenience init?(forWritingAtPath path: String) {
        // Mock implementation - always return a valid handle for testing
        self.init(fileDescriptor: 1) // stdout for testing
    }
    
    func seekToEndOfFile() {
        // Mock implementation
    }
    
    func write(_ data: Data) {
        // Mock implementation - update the mock file manager
        if let content = String(data: data, encoding: .utf8),
           let mockFileManager = FileManager.default as? CSVServiceTests.MockFileManager {
            let fileName = "purchases.csv"
            let existingContent = mockFileManager.getFileContent(fileName: fileName) ?? ""
            mockFileManager.setFileContent(fileName: fileName, content: existingContent + content)
        }
    }
}