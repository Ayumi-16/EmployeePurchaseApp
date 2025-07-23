import Foundation

/// Represents an employee for authentication and purchase tracking.
public struct Employee: Codable, Equatable {
    /// Unique employee identifier.
    public let id: String
    /// Employee's full name.
    public let name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

