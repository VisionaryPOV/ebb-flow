import Foundation

enum UserPreferencesStore {
    private static let suiteName = "com.ebbflow.preferences"
    private static let lastStationKey = "com.ebbflow.lastSelectedStationID"
    private static let lastStationDataKey = "com.ebbflow.lastSelectedStation"
    private static let seededFavoriteKey = "com.ebbflow.didSeedDefaultFavorite"

    nonisolated(unsafe) private static var defaults: UserDefaults = {
        UserDefaults(suiteName: suiteName) ?? .standard
    }()

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func saveLastStation(_ station: TideStation) {
        if let data = try? encoder.encode(station) {
            defaults.set(data, forKey: lastStationDataKey)
        }
        defaults.set(station.id, forKey: lastStationKey)
    }

    static func saveLastStationID(_ id: String) {
        defaults.set(id, forKey: lastStationKey)
    }

    static func lastStation() -> TideStation? {
        if let data = defaults.data(forKey: lastStationDataKey),
           let station = try? decoder.decode(TideStation.self, from: data) {
            return station
        }
        if let id = lastStationID(), let station = TideStationCatalog.resolve(id: id) {
            return station
        }
        return nil
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
        defaults.removeObject(forKey: lastStationDataKey)
    }

    static var needsDefaultFavoriteSeed: Bool {
        !defaults.bool(forKey: seededFavoriteKey)
    }

    static func markDefaultFavoriteSeeded() {
        defaults.set(true, forKey: seededFavoriteKey)
    }

    static func resetAllForTesting() {
        defaults.removeObject(forKey: lastStationKey)
        defaults.removeObject(forKey: lastStationDataKey)
        defaults.removeObject(forKey: seededFavoriteKey)
        defaults.synchronize()
    }
}