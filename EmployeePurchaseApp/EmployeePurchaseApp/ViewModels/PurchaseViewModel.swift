import Foundation
import SwiftUI

/// ViewModel for managing purchase processing and payment method selection
@MainActor
final class PurchaseViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently selected payment method (requirement 4.1, 4.2)
    @Published var selectedPaymentMethod: PaymentMethod = .cash
    
    /// Whether purchase processing is in progress
    @Published var isProcessing = false
    
    /// Whether purchase has been completed successfully
    @Published var purchaseComplete = false
    
    /// Current error state for UI display
    @Published var currentError: AppError?
    
    /// Completed purchase records for display
    @Published var completedPurchases: [Purchase] = []
    
    // MARK: - Dependencies
    
    private let csvService: CSVService
    
    // MARK: - Initialization
    
    init(csvService: CSVService = CSVService()) {
        self.csvService = csvService
    }
    
    // MARK: - Public Methods
    
    /// Processes the purchase for all items in the cart (requirement 4.3, 4.4)
    /// - Parameters:
    ///   - employee: Current logged-in employee
    ///   - items: Cart items to purchase
    /// - Returns: Success status
    @discardableResult
    func processPurchase(employee: Employee, items: [CartItem]) async -> Bool {
        clearError()
        isProcessing = true
        
        defer { isProcessing = false }
        
        // Validate inputs
        guard !items.isEmpty else {
            currentError = AppError.purchaseFailed
            return false
        }
        
        do {
            // Create purchase records for each cart item
            let purchases = createPurchaseRecords(employee: employee, items: items)
            
            // Save each purchase record to CSV (requirement 4.3)
            for purchase in purchases {
                try await csvService.appendPurchase(purchase)
            }
            
            // Store completed purchases for display
            completedPurchases = purchases
            
            // Mark purchase as complete (requirement 4.5)
            purchaseComplete = true
            
            return true
            
        } catch {
            // Handle purchase failure (requirement 4.5)
            currentError = AppError.purchaseFailed
            purchaseComplete = false
            return false
        }
    }
    
    /// Resets the purchase state for a new purchase (requirement 4.6)
    func startNewPurchase() {
        clearError()
        purchaseComplete = false
        completedPurchases.removeAll()
        selectedPaymentMethod = .cash
    }
    
    /// Validates if purchase can be processed
    /// - Parameters:
    ///   - employee: Employee to validate
    ///   - items: Cart items to validate
    /// - Returns: True if purchase can be processed
    func canProcessPurchase(employee: Employee?, items: [CartItem]) -> Bool {
        guard employee != nil else { return false }
        guard !items.isEmpty else { return false }
        guard !isProcessing else { return false }
        return true
    }
    
    /// Gets the total amount for the purchase
    /// - Parameter items: Cart items
    /// - Returns: Total amount
    func getTotalAmount(for items: [CartItem]) -> Int {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    /// Gets formatted total amount string
    /// - Parameter items: Cart items
    /// - Returns: Formatted total amount
    func getFormattedTotalAmount(for items: [CartItem]) -> String {
        let total = getTotalAmount(for: items)
        return "¥\(total.formatted())"
    }
    
    /// Gets the payment method display name
    var paymentMethodDisplayName: String {
        switch selectedPaymentMethod {
        case .cash:
            return "現金"
        case .payrollDeduction:
            return "給与天引き"
        }
    }
    
    /// Gets all available payment methods
    var availablePaymentMethods: [PaymentMethod] {
        [.cash, .payrollDeduction]
    }
    
    /// Gets display name for a payment method
    /// - Parameter method: Payment method
    /// - Returns: Display name
    func displayName(for method: PaymentMethod) -> String {
        switch method {
        case .cash:
            return "現金"
        case .payrollDeduction:
            return "給与天引き"
        }
    }
    
    /// Selects a payment method (requirement 4.1, 4.2)
    /// - Parameter method: Payment method to select
    func selectPaymentMethod(_ method: PaymentMethod) {
        clearError()
        selectedPaymentMethod = method
    }
    
    /// Clears the current error state
    func clearError() {
        currentError = nil
    }
    
    // MARK: - Private Methods
    
    /// Creates purchase records from cart items (requirement 4.4)
    /// - Parameters:
    ///   - employee: Employee making the purchase
    ///   - items: Cart items to convert to purchase records
    /// - Returns: Array of purchase records
    private func createPurchaseRecords(employee: Employee, items: [CartItem]) -> [Purchase] {
        let purchaseDate = Date()
        
        return items.map { item in
            Purchase(
                purchaseDate: purchaseDate,
                employeeId: employee.id,
                employeeName: employee.name,
                productId: item.product.productId,
                productName: item.product.name,
                category: item.product.category,
                size: item.selectedSize,
                quantity: item.quantity,
                unitPrice: item.product.price,
                paymentMethod: selectedPaymentMethod,
                status: .success, // Set to success since we're processing successfully
                brand: item.product.brand,
                notes: item.product.notes
            )
        }
    }
}

// MARK: - Purchase Summary Helper

extension PurchaseViewModel {
    /// Gets a summary of the completed purchase for display
    var purchaseSummary: PurchaseSummary? {
        guard purchaseComplete, !completedPurchases.isEmpty else { return nil }
        
        let totalAmount = completedPurchases.reduce(0) { $0 + $1.totalAmount }
        let totalItems = completedPurchases.reduce(0) { $0 + $1.quantity }
        let uniqueProducts = Set(completedPurchases.map { $0.productId }).count
        
        return PurchaseSummary(
            totalAmount: totalAmount,
            totalItems: totalItems,
            uniqueProducts: uniqueProducts,
            paymentMethod: selectedPaymentMethod,
            purchaseDate: completedPurchases.first?.purchaseDate ?? Date()
        )
    }
}

/// Summary information for a completed purchase
struct PurchaseSummary {
    let totalAmount: Int
    let totalItems: Int
    let uniqueProducts: Int
    let paymentMethod: PaymentMethod
    let purchaseDate: Date
    
    var formattedTotalAmount: String {
        "¥\(totalAmount.formatted())"
    }
    
    var formattedPurchaseDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: purchaseDate)
    }
    
    var paymentMethodDisplayName: String {
        switch paymentMethod {
        case .cash:
            return "現金"
        case .payrollDeduction:
            return "給与天引き"
        }
    }
}