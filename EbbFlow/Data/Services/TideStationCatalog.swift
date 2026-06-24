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
}