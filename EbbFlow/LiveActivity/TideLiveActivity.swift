import ActivityKit
import Foundation

struct TideActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let stationName: String
        let height: Double
        let isRising: Bool
        let nextExtremeLabel: String
        let nextExtremeTime: Date?
    }

    let stationID: String
}

enum TideLiveActivityManager {
    static func start(payload: SharedTideSnapshotPayload) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = TideActivityAttributes(stationID: payload.stationID)
        let nextLabel: String
        if let kind = payload.nextExtremeKind, let height = payload.nextExtremeHeight {
            nextLabel = "\(kind == "H" ? "High" : "Low") \(String(format: "%.1f", height)) ft"
        } else {
            nextLabel = "Next extreme"
        }
        let state = TideActivityAttributes.ContentState(
            stationName: payload.stationName,
            height: payload.currentHeight,
            isRising: payload.isRising,
            nextExtremeLabel: nextLabel,
            nextExtremeTime: payload.nextExtremeTime
        )
        _ = try? Activity<TideActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: state, staleDate: Date().addingTimeInterval(3600)),
            pushType: nil
        )
    }

    static func timelineEntry(from payload: SharedTideSnapshotPayload, now: Date = Date()) -> TideLiveActivityEntry {
        TideLiveActivityEntry(
            date: now,
            stationName: payload.stationName,
            height: payload.currentHeight,
            isRising: payload.isRising
        )
    }
}

struct TideLiveActivityEntry: Sendable, Equatable {
    let date: Date
    let stationName: String
    let height: Double
    let isRising: Bool
}