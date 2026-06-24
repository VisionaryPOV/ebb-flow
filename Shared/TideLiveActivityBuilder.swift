import Foundation

struct TideLiveActivityEntry: Sendable, Equatable {
    let date: Date
    let stationName: String
    let height: Double
    let isRising: Bool
}

struct TideLiveActivityContent: Sendable, Equatable {
    let stationName: String
    let height: Double
    let isRising: Bool
    let nextExtremeLabel: String
    let nextExtremeTime: Date?
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

    static func content(from payload: SharedTideSnapshotPayload) -> TideLiveActivityContent {
        let nextLabel: String
        if let kind = payload.nextExtremeKind, let height = payload.nextExtremeHeight {
            nextLabel = "\(kind == "H" ? "High" : "Low") \(String(format: "%.1f", height)) ft"
        } else {
            nextLabel = "Next extreme"
        }

        return TideLiveActivityContent(
            stationName: payload.stationName,
            height: payload.currentHeight,
            isRising: payload.isRising,
            nextExtremeLabel: nextLabel,
            nextExtremeTime: payload.nextExtremeTime
        )
    }

    static func hasActiveCountdown(for content: TideLiveActivityContent, at date: Date = Date()) -> Bool {
        guard let nextExtremeTime = content.nextExtremeTime else { return false }
        return nextExtremeTime > date
    }
}