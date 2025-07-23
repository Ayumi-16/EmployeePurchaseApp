import XCTest
@testable import EmployeePurchaseApp

@MainActor
final class CartViewModelTests: XCTestCase {
    
    private var viewModel: CartViewModel!
    private var sampleProduct: Product!
    
    override func setUp() {
        super.setUp()
        viewModel = CartViewModel()
        sampleProduct = Product(
            productId: "TEST001",
            name: "テストシューズ",
            category: "shoes",
            price: 5000,
            sizes: ["S", "M", "L"],
            stock: 10,
            brand: "TestBrand",
            notes: "テスト用商品"
        )
    }
    
    override func tearDown() {
        viewModel = nil
        sampleProduct = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.itemCount, 0)
        XCTAssertEqual(viewModel.uniqueItemCount, 0)
        XCTAssertEqual(viewModel.totalAmount, 0)
        XCTAssertFalse(viewModel.hasItems)
        XCTAssertNil(viewModel.currentError)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Add Item Tests (Requirement 3.4)
    
    func testAddItemSuccess() {
        let success = viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        
        XCTAssertTrue(success)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.itemCount, 2)
        XCTAssertEqual(viewModel.uniqueItemCount, 1)
        XCTAssertEqual(viewModel.totalAmount, 10000) // 5000 * 2
        XCTAssertTrue(viewModel.hasItems)
        XCTAssertNil(viewModel.currentError)
    }
    
    func testAddItemExceedsStock() {
        let success = viewModel.addItem(sampleProduct, size: "M", quantity: 15) // Exceeds stock of 10
        
        XCTAssertFalse(success)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertNotNil(viewModel.currentError)
        XCTAssertEqual(viewModel.currentError, AppError.purchaseFailed)
    }
    
    func testAddSameItemCombinesQuantity() {
        // Add first item
        let success1 = viewModel.addItem(sampleProduct, size: "M", quantity: 3)
        XCTAssertTrue(success1)
        XCTAssertEqual(viewModel.uniqueItemCount, 1)
        XCTAssertEqual(viewModel.itemCount, 3)
        
        // Add same item again
        let success2 = viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        XCTAssertTrue(success2)
        XCTAssertEqual(viewModel.uniqueItemCount, 1) // Still one unique item
        XCTAssertEqual(viewModel.itemCount, 5) // Combined quantity
        XCTAssertEqual(viewModel.totalAmount, 25000) // 5000 * 5
    }
    
    func testAddSameItemExceedsCombinedStock() {
        // Add first item
        let success1 = viewModel.addItem(sampleProduct, size: "M", quantity: 8)
        XCTAssertTrue(success1)
        
        // Try to add more that would exceed stock
        let success2 = viewModel.addItem(sampleProduct, size: "M", quantity: 5) // 8 + 5 = 13 > 10
        XCTAssertFalse(success2)
        XCTAssertEqual(viewModel.itemCount, 8) // Should remain unchanged
        XCTAssertNotNil(viewModel.currentError)
    }
    
    func testAddDifferentSizesSeparately() {
        let success1 = viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        let success2 = viewModel.addItem(sampleProduct, size: "L", quantity: 3)
        
        XCTAssertTrue(success1)
        XCTAssertTrue(success2)
        XCTAssertEqual(viewModel.uniqueItemCount, 2) // Two different items
        XCTAssertEqual(viewModel.itemCount, 5) // Total quantity
        XCTAssertEqual(viewModel.totalAmount, 25000) // 5000 * 5
    }
    
    // MARK: - Remove Item Tests (Requirement 3.6)
    
    func testRemoveItemByIndex() {
        // Add items first
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        viewModel.addItem(sampleProduct, size: "L", quantity: 1)
        
        XCTAssertEqual(viewModel.uniqueItemCount, 2)
        
        // Remove first item
        viewModel.removeItem(at: 0)
        
        XCTAssertEqual(viewModel.uniqueItemCount, 1)
        XCTAssertEqual(viewModel.itemCount, 1)
        XCTAssertEqual(viewModel.totalAmount, 5000)
    }
    
    func testRemoveItemById() {
        // Add item
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        let itemId = viewModel.items.first!.id
        
        // Remove by ID
        viewModel.removeItem(withId: itemId)
        
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.totalAmount, 0)
    }
    
    func testRemoveItemInvalidIndex() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 1)
        
        // Try to remove with invalid index
        viewModel.removeItem(at: 5)
        
        XCTAssertEqual(viewModel.uniqueItemCount, 1) // Should remain unchanged
        XCTAssertNotNil(viewModel.currentError)
    }
    
    // MARK: - Update Quantity Tests (Requirements 3.6, 3.7)
    
    func testUpdateQuantitySuccess() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        
        let success = viewModel.updateQuantity(at: 0, quantity: 5)
        
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.itemCount, 5)
        XCTAssertEqual(viewModel.totalAmount, 25000) // Auto-recalculated
        XCTAssertNil(viewModel.currentError)
    }
    
    func testUpdateQuantityExceedsStock() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        
        let success = viewModel.updateQuantity(at: 0, quantity: 15) // Exceeds stock
        
        XCTAssertFalse(success)
        XCTAssertEqual(viewModel.itemCount, 2) // Should remain unchanged
        XCTAssertNotNil(viewModel.currentError)
    }
    
    func testUpdateQuantityToZeroRemovesItem() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        
        let success = viewModel.updateQuantity(at: 0, quantity: 0)
        
        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.totalAmount, 0)
    }
    
    func testUpdateQuantityById() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        let itemId = viewModel.items.first!.id
        
        let success = viewModel.updateQuantity(forId: itemId, quantity: 3)
        
        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.itemCount, 3)
        XCTAssertEqual(viewModel.totalAmount, 15000)
    }
    
    // MARK: - Validation Tests
    
    func testCanAddItemValidation() {
        // Valid case
        XCTAssertTrue(viewModel.canAddItem(sampleProduct, size: "M", quantity: 5))
        
        // Invalid size
        XCTAssertFalse(viewModel.canAddItem(sampleProduct, size: "XL", quantity: 1))
        
        // Invalid quantity
        XCTAssertFalse(viewModel.canAddItem(sampleProduct, size: "M", quantity: 0))
        XCTAssertFalse(viewModel.canAddItem(sampleProduct, size: "M", quantity: -1))
        
        // Exceeds stock
        XCTAssertFalse(viewModel.canAddItem(sampleProduct, size: "M", quantity: 15))
    }
    
    func testCanAddItemWithExistingItems() {
        // Add existing item
        viewModel.addItem(sampleProduct, size: "M", quantity: 7)
        
        // Can add more within stock limit
        XCTAssertTrue(viewModel.canAddItem(sampleProduct, size: "M", quantity: 3)) // 7 + 3 = 10
        
        // Cannot add more that would exceed stock
        XCTAssertFalse(viewModel.canAddItem(sampleProduct, size: "M", quantity: 4)) // 7 + 4 = 11 > 10
        
        // Can add different size
        XCTAssertTrue(viewModel.canAddItem(sampleProduct, size: "L", quantity: 5))
    }
    
    func testGetCurrentQuantity() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 3)
        viewModel.addItem(sampleProduct, size: "L", quantity: 2)
        
        XCTAssertEqual(viewModel.getCurrentQuantity(for: "TEST001", size: "M"), 3)
        XCTAssertEqual(viewModel.getCurrentQuantity(for: "TEST001", size: "L"), 2)
        XCTAssertEqual(viewModel.getCurrentQuantity(for: "TEST001", size: "S"), 0)
        XCTAssertEqual(viewModel.getCurrentQuantity(for: "NONEXISTENT", size: "M"), 0)
    }
    
    func testGetMaxAdditionalQuantity() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 7)
        
        XCTAssertEqual(viewModel.getMaxAdditionalQuantity(for: sampleProduct, size: "M"), 3) // 10 - 7
        XCTAssertEqual(viewModel.getMaxAdditionalQuantity(for: sampleProduct, size: "L"), 10) // No existing items
    }
    
    // MARK: - Clear Cart Tests
    
    func testClearCart() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        viewModel.addItem(sampleProduct, size: "L", quantity: 3)
        
        XCTAssertFalse(viewModel.isEmpty)
        
        viewModel.clearCart()
        
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertEqual(viewModel.itemCount, 0)
        XCTAssertEqual(viewModel.totalAmount, 0)
        XCTAssertFalse(viewModel.hasItems)
        XCTAssertNil(viewModel.currentError)
    }
    
    // MARK: - Computed Properties Tests (Requirement 3.5)
    
    func testFormattedTotalAmount() {
        viewModel.addItem(sampleProduct, size: "M", quantity: 2)
        
        XCTAssertEqual(viewModel.formattedTotalAmount, "¥10,000")
    }
    
    func testHasItemsForBadgeDisplay() {
        // Empty cart
        XCTAssertFalse(viewModel.hasItems)
        
        // Add item
        viewModel.addItem(sampleProduct, size: "M", quantity: 1)
        XCTAssertTrue(viewModel.hasItems)
        
        // Clear cart
        viewModel.clearCart()
        XCTAssertFalse(viewModel.hasItems)
    }
}