import Foundation
@testable import EmployeePurchaseApp

/// Centralized factory for creating test data across all test suites
struct TestDataFactory {
    
    // MARK: - Employee Test Data
    
    static func createTestEmployees() -> [Employee] {
        return [
            Employee(id: "EMP001", name: "田中太郎"),
            Employee(id: "EMP002", name: "佐藤花子"),
            Employee(id: "EMP003", name: "鈴木次郎"),
            Employee(id: "EMP004", name: "高橋一郎"),
            Employee(id: "EMP005", name: "伊藤美咲"),
            Employee(id: "TEST001", name: "テスト太郎"),
            Employee(id: "TEST002", name: "テスト花子"),
            Employee(id: "ADMIN001", name: "管理者"),
            Employee(id: "ADMIN002", name: "副管理者"),
            Employee(id: "DEV001", name: "開発者")
        ]
    }
    
    static func createSingleTestEmployee() -> Employee {
        return Employee(id: "TEST001", name: "テスト太郎")
    }
    
    static func createAdminEmployee() -> Employee {
        return Employee(id: "ADMIN001", name: "管理者")
    }
    
    // MARK: - Product Test Data
    
    static func createTestProducts() -> [Product] {
        return [
            createTestShoeProduct(),
            createTestAccessoryProduct(),
            createTestClothingProduct(),
            createOutOfStockProduct(),
            createLimitedProduct()
        ]
    }
    
    static func createTestShoeProduct() -> Product {
        return Product(
            productId: "SHOE001",
            name: "テストランニングシューズ",
            category: "shoes",
            price: 8000,
            sizes: ["S", "M", "L", "XL"],
            stock: 10,
            brand: "TestSport",
            notes: "軽量で快適なランニングシューズ"
        )
    }
    
    static func createTestAccessoryProduct() -> Product {
        return Product(
            productId: "ACC001",
            name: "テストスポーツバッグ",
            category: "accessories",
            price: 3000,
            sizes: ["F"],
            stock: 5,
            brand: "TestBag",
            notes: "多機能スポーツバッグ"
        )
    }
    
    static func createTestClothingProduct() -> Product {
        return Product(
            productId: "CLOTH001",
            name: "テストTシャツ",
            category: "clothing",
            price: 2500,
            sizes: ["XS", "S", "M", "L", "XL", "XXL"],
            stock: 20,
            brand: "TestWear",
            notes: "吸汗速乾素材のTシャツ"
        )
    }
    
    static func createOutOfStockProduct() -> Product {
        return Product(
            productId: "SOLD001",
            name: "売り切れ商品",
            category: "limited",
            price: 5000,
            sizes: ["M"],
            stock: 0,
            brand: "TestLimited",
            notes: "限定商品（売り切れ）"
        )
    }
    
    static func createLimitedProduct() -> Product {
        return Product(
            productId: "LIMITED001",
            name: "限定商品",
            category: "limited",
            price: 12000,
            sizes: ["M", "L"],
            stock: 2,
            brand: "TestLimited",
            notes: "数量限定商品"
        )
    }
    
    // MARK: - CartItem Test Data
    
    static func createTestCartItems() -> [CartItem] {
        let products = createTestProducts()
        return [
            try! CartItem(product: products[0], selectedSize: "M", quantity: 1),
            try! CartItem(product: products[1], selectedSize: "F", quantity: 2),
            try! CartItem(product: products[2], selectedSize: "L", quantity: 1)
        ]
    }
    
    static func createSingleCartItem() -> CartItem {
        let product = createTestShoeProduct()
        return try! CartItem(product: product, selectedSize: "M", quantity: 1)
    }
    
    static func createCartItemWithMultipleQuantity() -> CartItem {
        let product = createTestAccessoryProduct()
        return try! CartItem(product: product, selectedSize: "F", quantity: 3)
    }
    
    // MARK: - Purchase Test Data
    
    static func createTestPurchases() -> [Purchase] {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return [
            Purchase(
                purchaseDate: dateFormatter.date(from: "2025-01-01 10:00:00")!,
                employeeId: "EMP001",
                employeeName: "田中太郎",
                productId: "SHOE001",
                productName: "テストランニングシューズ",
                category: "shoes",
                size: "M",
                quantity: 1,
                unitPrice: 8000,
                paymentMethod: .cash,
                status: .success,
                brand: "TestSport",
                notes: "軽量で快適なランニングシューズ"
            ),
            Purchase(
                purchaseDate: dateFormatter.date(from: "2025-01-02 14:30:00")!,
                employeeId: "EMP002",
                employeeName: "佐藤花子",
                productId: "ACC001",
                productName: "テストスポーツバッグ",
                category: "accessories",
                size: "F",
                quantity: 2,
                unitPrice: 3000,
                paymentMethod: .payrollDeduction,
                status: .success,
                brand: "TestBag",
                notes: "多機能スポーツバッグ"
            ),
            Purchase(
                purchaseDate: dateFormatter.date(from: "2025-01-03 09:15:00")!,
                employeeId: "EMP003",
                employeeName: "鈴木次郎",
                productId: "CLOTH001",
                productName: "テストTシャツ",
                category: "clothing",
                size: "L",
                quantity: 3,
                unitPrice: 2500,
                paymentMethod: .cash,
                status: .success,
                brand: "TestWear",
                notes: "吸汗速乾素材のTシャツ"
            )
        ]
    }
    
    static func createSingleTestPurchase() -> Purchase {
        return Purchase(
            purchaseDate: Date(),
            employeeId: "TEST001",
            employeeName: "テスト太郎",
            productId: "SHOE001",
            productName: "テストランニングシューズ",
            category: "shoes",
            size: "M",
            quantity: 1,
            unitPrice: 8000,
            paymentMethod: .cash,
            status: .success,
            brand: "TestSport",
            notes: "テスト購入"
        )
    }
    
    static func createFailedPurchase() -> Purchase {
        return Purchase(
            purchaseDate: Date(),
            employeeId: "TEST001",
            employeeName: "テスト太郎",
            productId: "SHOE001",
            productName: "テストランニングシューズ",
            category: "shoes",
            size: "M",
            quantity: 1,
            unitPrice: 8000,
            paymentMethod: .cash,
            status: .failure,
            brand: "TestSport",
            notes: "決済エラーテスト"
        )
    }
    
    // MARK: - QR Code Test Data
    
    static func createValidProductQRCode() -> String {
        let product = createTestShoeProduct()
        return createQRCodeForProduct(product)
    }
    
    static func createQRCodeForProduct(_ product: Product) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(product),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"product_id\":\"FALLBACK001\",\"name\":\"フォールバック商品\",\"category\":\"test\",\"price\":1000,\"sizes\":[\"M\"],\"stock\":1,\"brand\":\"Test\",\"notes\":\"テスト用\"}"
        }
        return jsonString
    }
    
    static func createInvalidQRCodes() -> [String] {
        return [
            "invalid_json_data",
            "",
            "{\"incomplete\": \"data\"}",
            "{\"product_id\":\"INCOMPLETE001\",\"name\":\"不完全商品\"}",
            "{\"name\":\"名前のみ商品\",\"price\":1000}",
            "not_json_at_all",
            "{malformed json}",
            "null",
            "[]"
        ]
    }
    
    // MARK: - CSV Test Data
    
    static func createValidEmployeeCSV() -> String {
        return """
        id,name
        EMP001,田中太郎
        EMP002,佐藤花子
        EMP003,鈴木次郎
        EMP004,高橋一郎
        EMP005,伊藤美咲
        TEST001,テスト太郎
        TEST002,テスト花子
        ADMIN001,管理者
        ADMIN002,副管理者
        DEV001,開発者
        """
    }
    
    static func createInvalidEmployeeCSV() -> String {
        return """
        id,name
        EMP001
        EMP002,佐藤花子,extra_column
        EMP003,鈴木次郎
        ,田中太郎
        EMP005
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
    
    static func createValidPurchasesCSV() -> String {
        let header = "purchase_date,employee_id,employee_name,product_id,product_name,category,size,quantity,unit_price,total_amount,payment_method,status,brand,notes"
        let rows = """
        2025-01-01 10:00:00,EMP001,田中太郎,SHOE001,テストランニングシューズ,shoes,M,1,8000,8000,cash,success,TestSport,軽量で快適なランニングシューズ
        2025-01-02 14:30:00,EMP002,佐藤花子,ACC001,テストスポーツバッグ,accessories,F,2,3000,6000,payrollDeduction,success,TestBag,多機能スポーツバッグ
        2025-01-03 09:15:00,EMP003,鈴木次郎,CLOTH001,テストTシャツ,clothing,L,3,2500,7500,cash,success,TestWear,吸汗速乾素材のTシャツ
        """
        return header + "\n" + rows
    }
    
    // MARK: - Test Scenarios
    
    struct QRScanScenario {
        let name: String
        let qrCode: String
        let shouldSucceed: Bool
        let expectedProductId: String?
        let expectedError: AppError?
    }
    
    static func createQRScanScenarios() -> [QRScanScenario] {
        return [
            QRScanScenario(
                name: "Valid Shoe Product",
                qrCode: createQRCodeForProduct(createTestShoeProduct()),
                shouldSucceed: true,
                expectedProductId: "SHOE001",
                expectedError: nil
            ),
            QRScanScenario(
                name: "Valid Accessory Product",
                qrCode: createQRCodeForProduct(createTestAccessoryProduct()),
                shouldSucceed: true,
                expectedProductId: "ACC001",
                expectedError: nil
            ),
            QRScanScenario(
                name: "Out of Stock Product",
                qrCode: createQRCodeForProduct(createOutOfStockProduct()),
                shouldSucceed: true,
                expectedProductId: "SOLD001",
                expectedError: nil
            ),
            QRScanScenario(
                name: "Invalid JSON",
                qrCode: "invalid_json_data",
                shouldSucceed: false,
                expectedProductId: nil,
                expectedError: .qrCodeInvalid
            ),
            QRScanScenario(
                name: "Empty QR Code",
                qrCode: "",
                shouldSucceed: false,
                expectedProductId: nil,
                expectedError: .qrCodeInvalid
            ),
            QRScanScenario(
                name: "Incomplete Product Data",
                qrCode: "{\"product_id\":\"INCOMPLETE001\",\"name\":\"不完全商品\"}",
                shouldSucceed: false,
                expectedProductId: nil,
                expectedError: .qrCodeInvalid
            )
        ]
    }
    
    struct NFCTestScenario {
        let name: String
        let employeeId: String?
        let shouldSucceed: Bool
        let expectedError: AppError?
    }
    
    static func createNFCTestScenarios() -> [NFCTestScenario] {
        return [
            NFCTestScenario(
                name: "Valid Employee",
                employeeId: "EMP001",
                shouldSucceed: true,
                expectedError: nil
            ),
            NFCTestScenario(
                name: "Invalid Employee",
                employeeId: "INVALID001",
                shouldSucceed: false,
                expectedError: .employeeNotFound
            ),
            NFCTestScenario(
                name: "Empty Employee ID",
                employeeId: "",
                shouldSucceed: false,
                expectedError: .nfcReadFailed
            ),
            NFCTestScenario(
                name: "Nil Employee ID",
                employeeId: nil,
                shouldSucceed: false,
                expectedError: .nfcReadFailed
            )
        ]
    }
    
    // MARK: - Date Utilities
    
    static func createTestDate(dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString) ?? Date()
    }
    
    static func formatDateForCSV(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // MARK: - Error Test Data
    
    static func createAllAppErrors() -> [AppError] {
        return [
            .nfcReadFailed,
            .nfcUnavailable,
            .qrCodeInvalid,
            .csvImportFailed,
            .purchaseFailed,
            .networkError,
            .fileNotFound,
            .employeeNotFound,
            .sessionExpired,
            .sessionInvalid,
            .cameraUnavailable,
            .cameraPermissionDenied,
            .qrCodeScanFailed
        ]
    }
    
    // MARK: - File Path Utilities
    
    static func getTestDataPath(fileName: String) -> String {
        return "EmployeePurchaseAppTests/TestData/\(fileName)"
    }
    
    static func getTestEmployeesCSVPath() -> String {
        return getTestDataPath(fileName: "employees_test.csv")
    }
    
    static func getTestPurchasesCSVPath() -> String {
        return getTestDataPath(fileName: "purchases_test.csv")
    }
    
    static func getQRTestDataPath() -> String {
        return getTestDataPath(fileName: "qr_test_data.json")
    }
}