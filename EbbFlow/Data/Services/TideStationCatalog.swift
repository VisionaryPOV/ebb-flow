import Foundation

enum TideStationCatalog {
    private static let knownStations: [String: TideStation] = [
        "9410840": .marinaDelRey
    ]
    nonisolated(unsafe) private static var registry: [String: NOAAStationRecord] = [:]

    static func register(_ records: [NOAAStationRecord]) {
        registry = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
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
        timeZone(forStationID: station.id, latitude: station.latitude, longitude: station.longitude)
    }

    static func timeZone(forStationID id: String) -> TimeZone {
        timeZone(forStationID: id, latitude: nil, longitude: nil)
    }

    private static func timeZone(forStationID id: String, latitude: Double?, longitude: Double?) -> TimeZone {
        if let record = registry[id] ?? knownRecord(for: id) {
            return NOAAStationDiscovery.timeZone(for: record)
        }
        if id == TideStation.marinaDelRey.id {
            return TideDataTransformer.noaaLocalTimeZone
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
            state: "CA",
            type: "R",
            timezonecorr: -8
        )
    }
}