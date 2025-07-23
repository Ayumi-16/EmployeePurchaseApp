import Foundation

/// Represents a purchasable product decoded from a QR code JSON payload.
public struct Product: Codable {
    /// Unique product identifier.
    public let productId: String
    /// Product name.
    public let name: String
    /// Category such as shoes or clothes.
    public let category: String
    /// Unit price of the product.
    public let price: Int
    /// Available size options.
    public let sizes: [String]
    /// Remaining stock quantity.
    public let stock: Int
    /// Brand or manufacturer.
    public let brand: String
    /// Additional information.
    public let notes: String

    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, category, price, sizes, stock, brand, notes
    }
}

