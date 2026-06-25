import Foundation

enum TideStationCatalog {
    private static let knownStations: [String: TideStation] = [
        "9410840": .marinaDelRey
    ]
    nonisolated(unsafe) private static var registry: [String: NOAAStationRecord] = [:]

    static func register(_ records: [NOAAStationRecord]) {
        registry = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
    }

    static func clearRegistryForTesting() {
        registry = [:]
    }

    static func record(for id: String) -> NOAAStationRecord? {
        registry[id]
    }

    static func resolve(id: String) -> TideStation? {
        if let known = knownStations[id] {
            return known
        }
        if let record = registry[id] {
            return TideStationResolver.makeStation(from: record)
        }
        return nil
    }

    static func coordinateKey(for station: TideStation) -> String {
        "\(station.latitude),\(station.longitude)"
    }

    static func timeZone(for station: TideStation) -> TimeZone {
        if let record = registry[station.id] ?? knownRecord(for: station.id) {
            return NOAAStationDiscovery.timeZone(for: record)
        }
        return timeZone(forState: station.state)
    }

    static func timeZone(forStationID id: String) -> TimeZone {
        if let record = registry[id] ?? knownRecord(for: id) {
            return NOAAStationDiscovery.timeZone(for: record)
        }
        if let persisted = UserPreferencesStore.lastStation(), persisted.id == id {
            return timeZone(forState: persisted.state)
        }
        if id == TideStation.marinaDelRey.id {
            return timeZone(forState: "CA")
        }
        return timeZone(forState: "CA")
    }

    static func timeZone(forState state: String) -> TimeZone {
        if let identifier = NOAAStationDiscovery.timeZoneIdentifier(for: state),
           let timeZone = TimeZone(identifier: identifier) {
            return timeZone
        }
        return TideDataTransformer.noaaLocalTimeZone
    }

    private static func knownRecord(for id: String) -> NOAAStationRecord? {
        guard let station = knownStations[id] else { return nil }
        return NOAAStationRecord(
            id: station.id,
            name: station.name,
            lat: station.latitude,
            lng: station.longitude,
            state: station.state,
            type: "R",
            timezonecorr: -8
        )
    }
}