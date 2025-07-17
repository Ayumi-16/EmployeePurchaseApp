import Foundation

/// Represents an employee for authentication and purchase tracking.
struct Employee: Codable {
    /// Unique employee identifier.
    let id: String
    /// Employee's full name.
    let name: String
}

