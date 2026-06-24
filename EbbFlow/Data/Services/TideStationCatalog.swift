import Foundation

enum TideStationCatalog {
    private static let stations: [String: TideStation] = [
        "9410840": .marinaDelRey
    ]

    static func resolve(id: String) -> TideStation? {
        stations[id]
    }

    static func coordinateKey(for station: TideStation) -> String {
        "\(station.latitude),\(station.longitude)"
    }

    static func timeZone(for station: TideStation) -> TimeZone {
        // Catalog stations use NOAA local civil time; extend per-station as catalog grows.
        TideDataTransformer.noaaLocalTimeZone
    }
}