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
    var photoPath: String
    var personalOffsetFeet: Double
    var createdAt: Date

    init(
        station: TideStation,
        notes: String = "",
        photoPath: String = "",
        personalOffsetFeet: Double = 0
    ) {
        self.stationID = station.id
        self.name = station.name
        self.latitude = station.latitude
        self.longitude = station.longitude
        self.datum = station.datum
        self.notes = notes
        self.photoPath = photoPath
        self.personalOffsetFeet = personalOffsetFeet
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

    func adjustedHeight(_ height: Double) -> Double {
        height + personalOffsetFeet
    }
}