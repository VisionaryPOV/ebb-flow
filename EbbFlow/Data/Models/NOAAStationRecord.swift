import CoreLocation
import Foundation

struct NOAAStationRecord: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
    let state: String
    let type: String
    let timezonecorr: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var isReferenceStation: Bool { type == "R" }
}

struct NOAAStationListResponse: Decodable, Sendable {
    let count: Int?
    let stations: [NOAAStationRecord]
}