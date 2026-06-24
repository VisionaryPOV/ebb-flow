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

    func addSpot(for station: TideStation, notes: String = "") throws {
        let descriptor = FetchDescriptor<FavoriteSpot>(
            predicate: #Predicate { $0.stationID == station.id }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.notes = notes
            try modelContext.save()
            return
        }

        modelContext.insert(FavoriteSpot(station: station, notes: notes))
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
        let descriptor = FetchDescriptor<FavoriteSpot>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        return try !modelContext.fetch(descriptor).isEmpty
    }
}