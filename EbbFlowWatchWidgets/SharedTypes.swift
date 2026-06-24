import Foundation

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