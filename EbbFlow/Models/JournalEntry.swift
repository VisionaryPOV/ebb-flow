import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var stationID: String
    var stationName: String
    var recordedAt: Date
    var tideHeightFeet: Double
    var tideKindRaw: String
    var notes: String
    var photoPath: String

    init(
        id: UUID = UUID(),
        station: TideStation,
        recordedAt: Date = Date(),
        tideHeightFeet: Double,
        tideKind: TideKind?,
        notes: String = "",
        photoPath: String = ""
    ) {
        self.id = id
        self.stationID = station.id
        self.stationName = station.name
        self.recordedAt = recordedAt
        self.tideHeightFeet = tideHeightFeet
        self.tideKindRaw = tideKind?.rawValue ?? ""
        self.notes = notes
        self.photoPath = photoPath
    }

    var tideKind: TideKind? {
        TideKind(rawValue: tideKindRaw)
    }
}