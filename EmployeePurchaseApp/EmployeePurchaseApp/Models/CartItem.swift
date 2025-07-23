import Foundation

/// Represents an item in the shopping cart with selected options and quantity.
public struct CartItem: Identifiable, Equatable {
    /// Unique identifier for the cart item.
    public let id = UUID()
    /// The product being purchased.
    public let product: Product
    /// Selected size for the product.
    public let selectedSize: String
    /// Quantity of the product to purchase.
    public var quantity: Int {
        didSet {
            // Ensure quantity is always positive
            if quantity < 1 {
                quantity = 1
            }
        }
    }
    
    /// Total price for this cart item (unit price × quantity).
    public var totalPrice: Int {
        product.price * quantity
    }
    
    /// Formatted total price string with currency symbol.
    public var formattedTotalPrice: String {
        "¥\(totalPrice.formatted())"
    }
    
    /// Creates a new cart item with validation.
    /// - Parameters:
    ///   - product: The product to add to cart
    ///   - selectedSize: The selected size (must be valid for the product)
    ///   - quantity: The desired quantity (must be positive and not exceed stock)
    /// - Throws: `CartItemError` if validation fails
    public init(product: Product, selectedSize: String, quantity: Int) throws {
        // Validate size selection
        guard product.sizes.contains(selectedSize) else {
            throw CartItemError.invalidSize
        }
        
        // Validate quantity
        guard quantity > 0 else {
            throw CartItemError.invalidQuantity
        }
        
        guard quantity <= product.stock else {
            throw CartItemError.insufficientStock
        }
        
        self.product = product
        self.selectedSize = selectedSize
        self.quantity = quantity
    }
    
    /// Validates if the requested quantity is available in stock.
    /// - Parameter requestedQuantity: The quantity to validate
    /// - Returns: `true` if the quantity is valid and available
    public func canUpdateQuantity(to requestedQuantity: Int) -> Bool {
        return requestedQuantity > 0 && requestedQuantity <= product.stock
    }
    
    /// Updates the quantity with validation.
    /// - Parameter newQuantity: The new quantity to set
    /// - Throws: `CartItemError` if the new quantity is invalid
    public mutating func updateQuantity(to newQuantity: Int) throws {
        guard canUpdateQuantity(to: newQuantity) else {
            if newQuantity <= 0 {
                throw CartItemError.invalidQuantity
            } else {
                throw CartItemError.insufficientStock
            }
        }
        self.quantity = newQuantity
    }
    
    /// Checks if this cart item represents the same product and size as another.
    /// - Parameter other: Another cart item to compare with
    /// - Returns: `true` if they represent the same product and size
    public func isSameProductAndSize(as other: CartItem) -> Bool {
        return product.productId == other.product.productId && 
               selectedSize == other.selectedSize
    }
}

/// Errors that can occur when working with cart items.
public enum CartItemError: Error, LocalizedError {
    case invalidSize
    case invalidQuantity
    case insufficientStock
    
    public var errorDescription: String? {
        switch self {
        case .invalidSize:
            return "選択されたサイズは利用できません。"
        case .invalidQuantity:
            return "数量は1以上である必要があります。"
        case .insufficientStock:
            return "在庫が不足しています。"
        }
    }
}

// MARK: - Equatable Implementation
extension CartItem {
    /// Two cart items are equal if they have the same product ID, selected size, and quantity.
    public static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.product.productId == rhs.product.productId &&
               lhs.selectedSize == rhs.selectedSize &&
               lhs.quantity == rhs.quantity
    }
}