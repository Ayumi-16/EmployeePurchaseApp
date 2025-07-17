import Foundation

/// Method of payment for a purchase.
enum PaymentMethod: String, Codable {
    case cash
    case payrollDeduction
}

/// Result status of a purchase transaction.
enum PurchaseStatus: String, Codable {
    case success
    case failure
}

/// Represents a completed purchase record.
struct Purchase: Codable {
    let purchaseDate: Date
    let employeeId: String
    let employeeName: String
    let productId: String
    let productName: String
    let category: String
    let size: String
    let quantity: Int
    let unitPrice: Int
    let totalAmount: Int
    let paymentMethod: PaymentMethod
    let status: PurchaseStatus
    let brand: String
    let notes: String

    /// Creates a `Purchase` and calculates the `totalAmount` from quantity and unit price.
    init(purchaseDate: Date,
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

