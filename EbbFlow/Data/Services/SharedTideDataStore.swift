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

    static func write(_ snapshot: TideSnapshot) {
        let state = snapshot.currentState
        let payload = SharedTideSnapshotPayload(
            stationID: snapshot.station.id,
            stationName: snapshot.station.name,
            currentHeight: state.height,
            isRising: state.isRising,
            nextExtremeTime: state.nextExtreme?.time,
            nextExtremeKind: state.nextExtreme?.kind.rawValue,
            nextExtremeHeight: state.nextExtreme?.height,
            fetchedAt: snapshot.fetchedAt
        )
        guard let data = try? JSONEncoder().encode(payload),
              let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

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
        let refresh = now.addingTimeInterval(15 * 60)
        return [WidgetTideEntry(date: now, payload: payload, refreshDate: refresh)]
    }
}

struct WidgetTideEntry: Sendable, Equatable {
    let date: Date
    let payload: SharedTideSnapshotPayload
    let refreshDate: Date
}

struct WatchTideEntryData: Sendable, Equatable {
    let date: Date
    let height: Double
    let stationName: String
    let refreshDate: Date
}

enum WatchTimelineBuilder {
    static func entry(from payload: SharedTideSnapshotPayload?, now: Date = Date()) -> WatchTideEntryData {
        WatchTideEntryData(
            date: now,
            height: payload?.currentHeight ?? 0,
            stationName: payload?.stationName ?? "Ebb & Flow",
            refreshDate: now.addingTimeInterval(900)
        )
    }
}