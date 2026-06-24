import Foundation

struct TideLiveActivityEntry: Sendable, Equatable {
    let date: Date
    let stationName: String
    let height: Double
    let isRising: Bool
}

enum TideLiveActivityBuilder {
    static func timelineEntry(from payload: SharedTideSnapshotPayload, now: Date = Date()) -> TideLiveActivityEntry {
        TideLiveActivityEntry(
            date: now,
            stationName: payload.stationName,
            height: payload.currentHeight,
            isRising: payload.isRising
        )
    }
}