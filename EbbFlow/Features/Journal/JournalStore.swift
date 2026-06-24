import Foundation
import SwiftData

@MainActor
final class JournalStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func allEntries() throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.recordedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func addEntry(
        station: TideStation,
        tideHeightFeet: Double,
        tideKind: TideKind?,
        notes: String = "",
        photoPath: String = "",
        recordedAt: Date = Date()
    ) throws {
        modelContext.insert(
            JournalEntry(
                station: station,
                recordedAt: recordedAt,
                tideHeightFeet: tideHeightFeet,
                tideKind: tideKind,
                notes: notes,
                photoPath: photoPath
            )
        )
        try modelContext.save()
    }

    func removeEntry(id: UUID) throws {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.id == id }
        )
        for entry in try modelContext.fetch(descriptor) {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    func search(query: String) throws -> [JournalEntry] {
        let entries = try allEntries()
        guard !query.isEmpty else { return entries }
        let lowered = query.lowercased()
        return entries.filter {
            $0.stationName.lowercased().contains(lowered) ||
            $0.notes.lowercased().contains(lowered)
        }
    }
}