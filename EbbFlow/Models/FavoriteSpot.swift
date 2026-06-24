import Foundation
import SwiftData

@Model
final class FavoriteSpot {
    @Attribute(.unique) var stationID: String
    var name: String
    var latitude: Double
    var longitude: Double
    var datum: String
    var notes: String
    var createdAt: Date

    init(station: TideStation, notes: String = "") {
        self.stationID = station.id
        self.name = station.name
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.datum = station.datum
        self.notes = notes
        self.createdAt = Date()
    }

    var station: TideStation {
        TideStation(
            id: stationID,
            name: name,
            latitude: latitude,
            longitude: longitude,
            datum: datum
        )
    }
}