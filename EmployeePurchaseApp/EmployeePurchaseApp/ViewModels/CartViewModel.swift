import Foundation
import SwiftUI

/// ViewModel for managing shopping cart functionality
@MainActor
final class CartViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Items currently in the cart
    @Published var items: [CartItem] = []
    
    /// Total amount for all items in cart
    @Published var totalAmount: Int = 0
    
    /// Current error state for UI display
    @Published var currentError: AppError?
    
    /// Loading state for operations
    @Published var isLoading = false
    
    // MARK: - Computed Properties
    
    /// Number of items in cart (total quantity of all items)
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    /// Number of unique items in cart
    var uniqueItemCount: Int {
        items.count
    }
    
    /// Whether the cart is empty
    var isEmpty: Bool {
        items.isEmpty
    }
    
    /// Formatted total amount string
    var formattedTotalAmount: String {
        "¥\(totalAmount.formatted())"
    }
    
    /// Whether cart has items for badge display (requirement 3.5)
    var hasItems: Bool {
        !items.isEmpty
    }
    
    // MARK: - Public Methods
    
    /// Adds an item to the cart with stock validation (requirement 3.4)
    /// - Parameters:
    ///   - product: Product to add
    ///   - size: Selected size
    ///   - quantity: Quantity to add
    /// - Returns: Success status
    @discardableResult
    func addItem(_ product: Product, size: String, quantity: Int) -> Bool {
        clearError()
        isLoading = true
        
        defer { isLoading = false }
        
        do {
            // Validate stock availability before creating cart item
            guard quantity <= product.stock else {
                currentError = AppError.purchaseFailed // Using existing error for stock issues
                return false
            }
            
            let newItem = try CartItem(product: product, selectedSize: size, quantity: quantity)
            
            // Check if item with same product and size already exists
            if let existingIndex = items.firstIndex(where: { $0.isSameProductAndSize(as: newItem) }) {
                // Check if combined quantity would exceed stock
                let combinedQuantity = items[existingIndex].quantity + quantity
                guard combinedQuantity <= product.stock else {
                    currentError = AppError.purchaseFailed
                    return false
                }
                
                // Update existing item quantity
                try items[existingIndex].updateQuantity(to: combinedQuantity)
            } else {
                // Add new item
                items.append(newItem)
            }
            
            calculateTotal()
            return true
            
        } catch let error as CartItemError {
            // Convert CartItemError to AppError for consistent error handling
            currentError = AppError.purchaseFailed
            return false
        } catch {
            currentError = AppError.purchaseFailed
            return false
        }
    }
    
    /// Removes an item from the cart (requirement 3.6)
    /// - Parameter index: Index of item to remove
    func removeItem(at index: Int) {
        clearError()
        
        guard index >= 0 && index < items.count else {
            currentError = AppError.purchaseFailed
            return
        }
        
        items.remove(at: index)
        calculateTotal()
    }
    
    /// Removes an item by its ID
    /// - Parameter id: ID of the item to remove
    func removeItem(withId id: UUID) {
        clearError()
        
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            currentError = AppError.purchaseFailed
            return
        }
        
        items.remove(at: index)
        calculateTotal()
    }
    
    /// Updates the quantity of an item in the cart with stock validation (requirement 3.6, 3.7)
    /// - Parameters:
    ///   - index: Index of item to update
    ///   - quantity: New quantity
    /// - Returns: Success status
    @discardableResult
    func updateQuantity(at index: Int, quantity: Int) -> Bool {
        clearError()
        
        guard index >= 0 && index < items.count else {
            currentError = AppError.purchaseFailed
            return false
        }
        
        // Remove item if quantity is 0 or less
        if quantity <= 0 {
            removeItem(at: index)
            return true
        }
        
        do {
            // Validate against product stock
            let item = items[index]
            guard quantity <= item.product.stock else {
                currentError = AppError.purchaseFailed
                return false
            }
            
            try items[index].updateQuantity(to: quantity)
            calculateTotal() // Requirement 3.7: Auto-recalculate total
            return true
        } catch {
            currentError = AppError.purchaseFailed
            return false
        }
    }
    
    /// Updates the quantity of an item by its ID
    /// - Parameters:
    ///   - id: ID of the item to update
    ///   - quantity: New quantity
    /// - Returns: Success status
    @discardableResult
    func updateQuantity(forId id: UUID, quantity: Int) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            currentError = AppError.purchaseFailed
            return false
        }
        
        return updateQuantity(at: index, quantity: quantity)
    }
    
    /// Clears all items from the cart
    func clearCart() {
        clearError()
        items.removeAll()
        totalAmount = 0
    }
    
    /// Validates if a product can be added to cart with specified quantity
    /// - Parameters:
    ///   - product: Product to validate
    ///   - size: Selected size
    ///   - quantity: Desired quantity
    /// - Returns: True if the item can be added
    func canAddItem(_ product: Product, size: String, quantity: Int) -> Bool {
        // Check if size is valid
        guard product.sizes.contains(size) else { return false }
        
        // Check if quantity is valid
        guard quantity > 0 else { return false }
        
        // Check stock availability
        if let existingIndex = items.firstIndex(where: { 
            $0.product.productId == product.productId && $0.selectedSize == size 
        }) {
            // Check combined quantity against stock
            let combinedQuantity = items[existingIndex].quantity + quantity
            return combinedQuantity <= product.stock
        } else {
            // Check new item quantity against stock
            return quantity <= product.stock
        }
    }
    
    /// Gets the current quantity of a specific product and size in the cart
    /// - Parameters:
    ///   - productId: Product ID
    ///   - size: Selected size
    /// - Returns: Current quantity in cart (0 if not found)
    func getCurrentQuantity(for productId: String, size: String) -> Int {
        return items.first { $0.product.productId == productId && $0.selectedSize == size }?.quantity ?? 0
    }
    
    /// Gets the maximum additional quantity that can be added for a product
    /// - Parameters:
    ///   - product: Product to check
    ///   - size: Selected size
    /// - Returns: Maximum additional quantity that can be added
    func getMaxAdditionalQuantity(for product: Product, size: String) -> Int {
        let currentQuantity = getCurrentQuantity(for: product.productId, size: size)
        return max(0, product.stock - currentQuantity)
    }
    
    // MARK: - Private Methods
    
    /// Calculates the total amount for all items in cart (requirement 3.7)
    private func calculateTotal() {
        totalAmount = items.reduce(0) { $0 + $1.totalPrice }
    }
    
    /// Clears the current error state
    private func clearError() {
        currentError = nil
    }
}