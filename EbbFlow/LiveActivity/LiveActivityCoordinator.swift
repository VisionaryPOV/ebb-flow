import Foundation

enum LiveActivityCoordinator {
    static func publish(snapshot: TideSnapshot) async {
        let payload = SharedTideSnapshotPayload(snapshot: snapshot)
        #if canImport(ActivityKit) && !targetEnvironment(macCatalyst)
        await TideLiveActivityManager.start(payload: payload)
        #endif
    }
}