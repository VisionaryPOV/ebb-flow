import Foundation

enum TideKind: String, Codable, Sendable, CaseIterable {
    case high = "H"
    case low = "L"

    var label: String {
        switch self {
        case .high: "High"
        case .low: "Low"
        }
    }
}