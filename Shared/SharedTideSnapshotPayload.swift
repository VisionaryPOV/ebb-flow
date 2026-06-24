import Foundation

struct SharedTideSnapshotPayload: Codable, Sendable, Equatable {
    let stationID: String
    let stationName: String
    let currentHeight: Double
    let isRising: Bool
    let nextExtremeTime: Date?
    let nextExtremeKind: String?
    let nextExtremeHeight: Double?
    let fetchedAt: Date
}