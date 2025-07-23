import XCTest
@testable import EmployeePurchaseApp

@MainActor
final class PurchaseViewModelTests: XCTestCase {
    
    private var viewModel: PurchaseViewModel!
    private var mockCSVService: MockCSVService!
    
    override func setUp() {
        super.setUp()
        mockCSVService = MockCSVService()
        viewModel = PurchaseViewModel(csvService: mockCSVService)
    }
    
    override func tearDown() {
        viewModel = nil
        mockCSVService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedPaymentMethod, .cash)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.purchaseComplete)
        XCTAssertNil(viewModel.currentError)
        XCTAssertTrue(viewModel.completedPurchases.isEmpty)
    }
    
    // MARK: - Payment Method Selection Tests (Requirements 4.1, 4.2)
    
    func testSelectPaymentMethod() {
        // Test selecting cash payment
        viewModel.selectPaymentMethod(.cash)
        XCTAssertEqual(viewModel.selectedPaymentMethod, .cash)
        XCTAssertEqual(viewModel.paymentMethodDisplayName, "現金")
        
        // Test selecting payroll deduction
        viewModel.selectPaymentMethod(.payrollDeduction)
        XCTAssertEqual(viewModel.selectedPaymentMethod, .payrollDeduction)
        XCTAssertEqual(viewModel.paymentMethodDisplayName, "給与天引き")
    }
    
    func testAvailablePaymentMethods() {
        let methods = viewModel.availablePaymentMethods
        XCTAssertEqual(methods.count, 2)
        XCTAssertTrue(methods.contains(.cash))
        XCTAssertTrue(methods.contains(.payrollDeduction))
    }
    
    func testPaymentMethodDisplayNames() {
        XCTAssertEqual(viewModel.displayName(for: .cash), "現金")
        XCTAssertEqual(viewModel.displayName(for: .payrollDeduction), "給与天引き")
    }
    
    // MARK: - Purchase Validation Tests
    
    func testCanProcessPurchase() {
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let product = createTestProduct()
        let cartItem = try! CartItem(product: product, selectedSize: "M", quantity: 2)
        let items = [cartItem]
        
        // Valid case
        XCTAssertTrue(viewModel.canProcessPurchase(employee: employee, items: items))
        
        // Invalid cases
        XCTAssertFalse(viewModel.canProcessPurchase(employee: nil, items: items))
        XCTAssertFalse(viewModel.canProcessPurchase(employee: employee, items: []))
        
        // Test processing state
        viewModel.isProcessing = true
        XCTAssertFalse(viewModel.canProcessPurchase(employee: employee, items: items))
    }
    
    // MARK: - Purchase Processing Tests (Requirements 4.3, 4.4, 4.5)
    
    func testSuccessfulPurchaseProcessing() async {
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let product = createTestProduct()
        let cartItem = try! CartItem(product: product, selectedSize: "M", quantity: 2)
        let items = [cartItem]
        
        mockCSVService.shouldSucceed = true
        viewModel.selectPaymentMethod(.payrollDeduction)
        
        let result = await viewModel.processPurchase(employee: employee, items: items)
        
        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.purchaseComplete)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertNil(viewModel.currentError)
        XCTAssertEqual(viewModel.completedPurchases.count, 1)
        
        // Verify purchase record details
        let purchase = viewModel.completedPurchases.first!
        XCTAssertEqual(purchase.employeeId, employee.id)
        XCTAssertEqual(purchase.employeeName, employee.name)
        XCTAssertEqual(purchase.productId, product.productId)
        XCTAssertEqual(purchase.quantity, 2)
        XCTAssertEqual(purchase.paymentMethod, .payrollDeduction)
        XCTAssertEqual(purchase.status, .success)
    }
    
    func testFailedPurchaseProcessing() async {
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let product = createTestProduct()
        let cartItem = try! CartItem(product: product, selectedSize: "M", quantity: 1)
        let items = [cartItem]
        
        mockCSVService.shouldSucceed = false
        
        let result = await viewModel.processPurchase(employee: employee, items: items)
        
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.purchaseComplete)
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertEqual(viewModel.currentError, AppError.purchaseFailed)
        XCTAssertTrue(viewModel.completedPurchases.isEmpty)
    }
    
    func testPurchaseWithEmptyCart() async {
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let items: [CartItem] = []
        
        let result = await viewModel.processPurchase(employee: employee, items: items)
        
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.purchaseComplete)
        XCTAssertEqual(viewModel.currentError, AppError.purchaseFailed)
    }
    
    // MARK: - Purchase Summary Tests
    
    func testPurchaseSummary() async {
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let product1 = createTestProduct(id: "PROD001", name: "商品1", price: 1000)
        let product2 = createTestProduct(id: "PROD002", name: "商品2", price: 2000)
        let items = [
            try! CartItem(product: product1, selectedSize: "M", quantity: 2),
            try! CartItem(product: product2, selectedSize: "L", quantity: 1)
        ]
        
        mockCSVService.shouldSucceed = true
        viewModel.selectPaymentMethod(.cash)
        
        _ = await viewModel.processPurchase(employee: employee, items: items)
        
        let summary = viewModel.purchaseSummary
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.totalAmount, 4000) // (1000 * 2) + (2000 * 1)
        XCTAssertEqual(summary?.totalItems, 3) // 2 + 1
        XCTAssertEqual(summary?.uniqueProducts, 2)
        XCTAssertEqual(summary?.paymentMethod, .cash)
    }
    
    // MARK: - New Purchase Tests (Requirement 4.6)
    
    func testStartNewPurchase() async {
        // First complete a purchase
        let employee = Employee(id: "TEST001", name: "テスト太郎")
        let product = createTestProduct()
        let cartItem = try! CartItem(product: product, selectedSize: "M", quantity: 1)
        let items = [cartItem]
        
        mockCSVService.shouldSucceed = true
        viewModel.selectPaymentMethod(.payrollDeduction)
        _ = await viewModel.processPurchase(employee: employee, items: items)
        
        // Verify purchase is complete
        XCTAssertTrue(viewModel.purchaseComplete)
        XCTAssertFalse(viewModel.completedPurchases.isEmpty)
        
        // Start new purchase
        viewModel.startNewPurchase()
        
        // Verify state is reset
        XCTAssertFalse(viewModel.purchaseComplete)
        XCTAssertTrue(viewModel.completedPurchases.isEmpty)
        XCTAssertEqual(viewModel.selectedPaymentMethod, .cash)
        XCTAssertNil(viewModel.currentError)
    }
    
    // MARK: - Total Amount Calculation Tests
    
    func testTotalAmountCalculation() {
        let product1 = createTestProduct(id: "PROD001", name: "商品1", price: 1500)
        let product2 = createTestProduct(id: "PROD002", name: "商品2", price: 800)
        let items = [
            try! CartItem(product: product1, selectedSize: "M", quantity: 3),
            try! CartItem(product: product2, selectedSize: "S", quantity: 2)
        ]
        
        let total = viewModel.getTotalAmount(for: items)
        let formattedTotal = viewModel.getFormattedTotalAmount(for: items)
        
        XCTAssertEqual(total, 6100) // (1500 * 3) + (800 * 2)
        XCTAssertEqual(formattedTotal, "¥6,100")
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        viewModel.currentError = AppError.purchaseFailed
        XCTAssertNotNil(viewModel.currentError)
        
        viewModel.clearError()
        XCTAssertNil(viewModel.currentError)
    }
    
    // MARK: - Helper Methods
    
    private func createTestProduct(
        id: String = "TEST001",
        name: String = "テスト商品",
        price: Int = 1000
    ) -> Product {
        return Product(
            productId: id,
            name: name,
            category: "テストカテゴリ",
            price: price,
            sizes: ["S", "M", "L"],
            stock: 10,
            brand: "テストブランド",
            notes: "テスト用商品"
        )
    }
}