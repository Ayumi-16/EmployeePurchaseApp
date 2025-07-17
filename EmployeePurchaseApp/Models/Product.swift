import Foundation

/// Represents a purchasable product decoded from a QR code JSON payload.
struct Product: Codable {
    /// Unique product identifier.
    let productId: String
    /// Product name.
    let name: String
    /// Category such as shoes or clothes.
    let category: String
    /// Unit price of the product.
    let price: Int
    /// Available size options.
    let sizes: [String]
    /// Remaining stock quantity.
    let stock: Int
    /// Brand or manufacturer.
    let brand: String
    /// Additional information.
    let notes: String

    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, category, price, sizes, stock, brand, notes
    }
}

