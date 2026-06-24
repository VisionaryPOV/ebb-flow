import Foundation
import SwiftData

@MainActor
final class SpotsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func allSpots() throws -> [FavoriteSpot] {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func spot(stationID: String) throws -> FavoriteSpot? {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        return try modelContext.fetch(descriptor).first
    }

    func addSpot(
        for station: TideStation,
        notes: String = "",
        photoPath: String = "",
        personalOffsetFeet: Double = 0
    ) throws {
        if let existing = try spot(stationID: station.id) {
            existing.notes = notes
            existing.photoPath = photoPath
            existing.personalOffsetFeet = personalOffsetFeet
            try modelContext.save()
            return
        }

        modelContext.insert(
            FavoriteSpot(
                station: station,
                notes: notes,
                photoPath: photoPath,
                personalOffsetFeet: personalOffsetFeet
            )
        )
        try modelContext.save()
    }

    func updateSpot(
        stationID: String,
        notes: String?,
        photoPath: String?,
        personalOffsetFeet: Double?
    ) throws {
        guard let existing = try spot(stationID: stationID) else {
            throw TideServiceError.cacheMiss
        }
        if let notes { existing.notes = notes }
        if let photoPath { existing.photoPath = photoPath }
        if let personalOffsetFeet { existing.personalOffsetFeet = personalOffsetFeet }
        try modelContext.save()
    }

    func removeSpot(stationID: String) throws {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        for spot in try modelContext.fetch(descriptor) {
            modelContext.delete(spot)
        }
        try modelContext.save()
    }

    func contains(stationID: String) throws -> Bool {
        try spot(stationID: stationID) != nil
    }
}