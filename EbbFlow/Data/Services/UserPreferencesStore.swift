import Foundation

enum UserPreferencesStore {
    private static let suiteName = "com.ebbflow.preferences"
    private static let lastStationKey = "com.ebbflow.lastSelectedStationID"
    private static let seededFavoriteKey = "com.ebbflow.didSeedDefaultFavorite"

    nonisolated(unsafe) private static var defaults: UserDefaults = {
        UserDefaults(suiteName: suiteName) ?? .standard
    }()

    static func saveLastStationID(_ id: String) {
        defaults.set(id, forKey: lastStationKey)
    }

    static func lastStationID() -> String? {
        if let value = defaults.string(forKey: lastStationKey) {
            return value
        }
        if let legacy = UserDefaults.standard.string(forKey: lastStationKey) {
            defaults.set(legacy, forKey: lastStationKey)
            return legacy
        }
        return nil
    }

    static func clearLastStationID() {
        defaults.removeObject(forKey: lastStationKey)
    }

    static var needsDefaultFavoriteSeed: Bool {
        !defaults.bool(forKey: seededFavoriteKey)
    }

    static func markDefaultFavoriteSeeded() {
        defaults.set(true, forKey: seededFavoriteKey)
    }

    static func resetAllForTesting() {
        defaults.removeObject(forKey: lastStationKey)
        defaults.removeObject(forKey: seededFavoriteKey)
        defaults.synchronize()
    }
}