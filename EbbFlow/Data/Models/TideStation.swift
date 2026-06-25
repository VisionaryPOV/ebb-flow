import CoreLocation
import Foundation

struct TideStation: Identifiable, Codable, Sendable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let datum: String
    let state: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        datum: String,
        state: String = "CA"
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.datum = datum
        self.state = state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        datum = try container.decode(String.self, forKey: .datum)
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? "CA"
    }

    static let marinaDelRey = TideStation(
        id: "9410840",
        name: "Marina del Rey",
        latitude: 33.9767,
        longitude: -118.4567,
        datum: "MLLW",
        state: "CA"
    )
}