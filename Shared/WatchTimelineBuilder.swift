import Foundation

struct WatchTideEntryData: Sendable, Equatable {
    let date: Date
    let height: Double
    let stationName: String
    let refreshDate: Date
}

enum WatchTimelineBuilder {
    static let refreshInterval: TimeInterval = 900

    static func entry(from payload: SharedTideSnapshotPayload?, now: Date = Date()) -> WatchTideEntryData {
        WatchTideEntryData(
            date: now,
            height: payload?.currentHeight ?? 0,
            stationName: payload?.stationName ?? "Ebb & Flow",
            refreshDate: now.addingTimeInterval(refreshInterval)
        )
    }

    static func complicationTimeline(from payload: SharedTideSnapshotPayload?, now: Date = Date()) -> (entry: WatchTideEntryData, refreshDate: Date) {
        let entry = entry(from: payload, now: now)
        return (entry, entry.refreshDate)
    }
}