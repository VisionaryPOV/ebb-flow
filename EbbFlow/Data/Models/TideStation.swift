import CoreLocation
import Foundation

struct TideStation: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let datum: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static let marinaDelRey = TideStation(
        id: "9410840",
        name: "Marina del Rey",
        latitude: 33.9767,
        longitude: -118.4567,
        datum: "MLLW"
    )
}