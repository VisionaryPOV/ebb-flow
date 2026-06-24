#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

enum TideLiveActivityManager {
    static func start(payload: SharedTideSnapshotPayload) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = TideLiveActivityBuilder.content(from: payload)
        let attributes = TideActivityAttributes(stationID: payload.stationID)
        let state = TideActivityAttributes.ContentState(
            stationName: content.stationName,
            height: content.height,
            isRising: content.isRising,
            nextExtremeLabel: content.nextExtremeLabel,
            nextExtremeTime: content.nextExtremeTime
        )
        _ = try? Activity<TideActivityAttributes>.request(
            attributes: attributes,
            content: .init(state: state, staleDate: Date().addingTimeInterval(3600)),
            pushType: nil
        )
    }
}
#endif