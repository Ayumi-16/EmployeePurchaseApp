import Foundation

/// Method of payment for a purchase.
public enum PaymentMethod: String, Codable {
    case cash
    case payrollDeduction
}

/// Result status of a purchase transaction.
public enum PurchaseStatus: String, Codable {
    case success
    case failure
}

/// Represents a completed purchase record.
public struct Purchase: Codable {
    public let purchaseDate: Date
    public let employeeId: String
    public let employeeName: String
    public let productId: String
    public let productName: String
    public let category: String
    public let size: String
    public let quantity: Int
    public let unitPrice: Int
    public let totalAmount: Int
    public let paymentMethod: PaymentMethod
    public let status: PurchaseStatus
    public let brand: String
    public let notes: String

    /// Creates a `Purchase` and calculates the `totalAmount` from quantity and unit price.
    public init(purchaseDate: Date,
         employeeId: String,
         employeeName: String,
         productId: String,
         productName: String,
         category: String,
         size: String,
         quantity: Int,
         unitPrice: Int,
         paymentMethod: PaymentMethod,
         status: PurchaseStatus,
         brand: String,
         notes: String) {
        self.purchaseDate = purchaseDate
        self.employeeId = employeeId
        self.employeeName = employeeName
        self.productId = productId
        self.productName = productName
        self.category = category
        self.size = size
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalAmount = unitPrice * quantity
        self.paymentMethod = paymentMethod
        self.status = status
        self.brand = brand
        self.notes = notes
    }
}

