import Foundation

enum UserPreferencesStore {
    private static let lastStationKey = "com.ebbflow.lastSelectedStationID"
    private static let seededFavoriteKey = "com.ebbflow.didSeedDefaultFavorite"

    static func saveLastStationID(_ id: String) {
        UserDefaults.standard.set(id, forKey: lastStationKey)
    }

    static func lastStationID() -> String? {
        UserDefaults.standard.string(forKey: lastStationKey)
    }

    static func clearLastStationID() {
        UserDefaults.standard.removeObject(forKey: lastStationKey)
    }

    static var needsDefaultFavoriteSeed: Bool {
        !UserDefaults.standard.bool(forKey: seededFavoriteKey)
    }

    static func markDefaultFavoriteSeeded() {
        UserDefaults.standard.set(true, forKey: seededFavoriteKey)
    }
}