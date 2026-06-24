import Foundation

enum SharedTideDataStore {
    static let appGroupID = "group.com.ebbflow.shared"
    static let snapshotKey = "latestTideSnapshot"

    static func write(payload: SharedTideSnapshotPayload, userDefaults: UserDefaults? = nil) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let defaults = userDefaults ?? UserDefaults(suiteName: appGroupID)
        guard let defaults else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func read(userDefaults: UserDefaults? = nil) -> SharedTideSnapshotPayload? {
        let defaults = userDefaults ?? UserDefaults(suiteName: appGroupID)
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey),
              let payload = try? JSONDecoder().decode(SharedTideSnapshotPayload.self, from: data) else {
            return nil
        }
        return payload
    }

    static func clear(userDefaults: UserDefaults? = nil) {
        let defaults = userDefaults ?? UserDefaults(suiteName: appGroupID)
        defaults?.removeObject(forKey: snapshotKey)
    }
}