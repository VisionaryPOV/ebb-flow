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

enum SharedTideDataStore {
    static let appGroupID = "group.com.ebbflow.shared"
    static let snapshotKey = "latestTideSnapshot"

    static func read() -> SharedTideSnapshotPayload? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey),
              let payload = try? JSONDecoder().decode(SharedTideSnapshotPayload.self, from: data) else {
            return nil
        }
        return payload
    }
}

enum WidgetTimelineBuilder {
    static func entries(from payload: SharedTideSnapshotPayload, now: Date = Date()) -> [WidgetTideEntry] {
        [WidgetTideEntry(date: now, payload: payload, refreshDate: now.addingTimeInterval(15 * 60))]
    }
}

struct WidgetTideEntry: Sendable, Equatable {
    let date: Date
    let payload: SharedTideSnapshotPayload
    let refreshDate: Date
}