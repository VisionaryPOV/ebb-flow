#if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
import ActivityKit
import Foundation

@MainActor
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
        let activityContent = ActivityContent(
            state: state,
            staleDate: Date().addingTimeInterval(3600)
        )

        let existing = Activity<TideActivityAttributes>.activities.first
        let action = TideLiveActivityLifecycle.action(
            existingStationID: existing?.attributes.stationID,
            newStationID: payload.stationID,
            hasExistingActivity: existing != nil
        )

        switch action {
        case .updateExisting:
            await existing?.update(activityContent)
        case .endAndRequest:
            for activity in Activity<TideActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            _ = try? Activity<TideActivityAttributes>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
        case .requestNew:
            _ = try? Activity<TideActivityAttributes>.request(
                attributes: attributes,
                content: activityContent,
                pushType: nil
            )
        }
    }
}
#endif