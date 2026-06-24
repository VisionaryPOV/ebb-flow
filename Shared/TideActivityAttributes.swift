#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

struct TideActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable, Sendable {
        let stationName: String
        let height: Double
        let isRising: Bool
        let nextExtremeLabel: String
        let nextExtremeTime: Date?
    }

    let stationID: String
}
#endif