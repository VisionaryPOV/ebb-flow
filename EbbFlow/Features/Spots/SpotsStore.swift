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
            if !photoPath.isEmpty, photoPath != existing.photoPath {
                PhotoStorage.delete(path: existing.photoPath)
            }
            existing.name = station.name
            existing.latitude = station.latitude
            existing.longitude = station.longitude
            existing.datum = station.datum
            existing.state = station.state
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
        name: String? = nil,
        notes: String?,
        photoPath: String?,
        personalOffsetFeet: Double?
    ) throws {
        guard let existing = try spot(stationID: stationID) else {
            throw TideServiceError.cacheMiss
        }
        if let name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            existing.name = name
        }
        if let notes { existing.notes = notes }
        if let photoPath {
            if photoPath != existing.photoPath {
                PhotoStorage.delete(path: existing.photoPath)
            }
            existing.photoPath = photoPath
        }
        if let personalOffsetFeet { existing.personalOffsetFeet = personalOffsetFeet }
        try modelContext.save()
    }

    func removeSpot(stationID: String) throws {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        for spot in try modelContext.fetch(descriptor) {
            PhotoStorage.delete(path: spot.photoPath)
            modelContext.delete(spot)
        }
        try modelContext.save()
    }

    func contains(stationID: String) throws -> Bool {
        try spot(stationID: stationID) != nil
    }
}