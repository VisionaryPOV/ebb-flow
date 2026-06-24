import Foundation
import SwiftData

@Model
final class CachedTideExtremeRecord {
    @Attribute(.unique) var key: String
    var stationID: String
    var time: Date
    var height: Double
    var kindRaw: String

    init(stationID: String, extreme: TideExtreme) {
        self.key = "\(stationID)-\(extreme.time.timeIntervalSince1970)-\(extreme.kind.rawValue)"
        self.stationID = stationID
        self.time = extreme.time
        self.height = extreme.height
        self.kindRaw = extreme.kind.rawValue
    }

    var extreme: TideExtreme {
        TideExtreme(
            time: time,
            height: height,
            kind: TideKind(rawValue: kindRaw) ?? .high
        )
    }
}

@Model
final class CachedTideHeightRecord {
    @Attribute(.unique) var key: String
    var stationID: String
    var time: Date
    var height: Double

    init(stationID: String, height: TideHeight) {
        self.key = "\(stationID)-\(height.time.timeIntervalSince1970)"
        self.stationID = stationID
        self.time = height.time
        self.height = height.height
    }

    var tideHeight: TideHeight {
        TideHeight(time: time, height: height)
    }
}

@Model
final class CachedTideMetadataRecord {
    @Attribute(.unique) var stationID: String
    var fetchedAt: Date

    init(stationID: String, fetchedAt: Date) {
        self.stationID = stationID
        self.fetchedAt = fetchedAt
    }
}

@MainActor
final class SwiftDataTideCache: TideCacheStoring {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func cachedExtremes(stationID: String) async -> [TideExtreme]? {
        let descriptor = FetchDescriptor<CachedTideExtremeRecord>(
            predicate: #Predicate { $0.stationID == stationID },
            sortBy: [SortDescriptor(\.time)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        guard !records.isEmpty else { return nil }
        return records.map(\.extreme)
    }

    func cachedHeights(stationID: String) async -> [TideHeight]? {
        let descriptor = FetchDescriptor<CachedTideHeightRecord>(
            predicate: #Predicate { $0.stationID == stationID },
            sortBy: [SortDescriptor(\.time)]
        )
        let records = (try? modelContext.fetch(descriptor)) ?? []
        guard !records.isEmpty else { return nil }
        return records.map(\.tideHeight)
    }

    func cachedFetchedAt(stationID: String) async -> Date? {
        let descriptor = FetchDescriptor<CachedTideMetadataRecord>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        return try? modelContext.fetch(descriptor).first?.fetchedAt
    }

    func store(
        extremes: [TideExtreme],
        heights: [TideHeight],
        stationID: String,
        fetchedAt: Date
    ) async throws {
        try deleteExisting(stationID: stationID)

        for extreme in extremes {
            modelContext.insert(CachedTideExtremeRecord(stationID: stationID, extreme: extreme))
        }
        for height in heights {
            modelContext.insert(CachedTideHeightRecord(stationID: stationID, height: height))
        }
        modelContext.insert(CachedTideMetadataRecord(stationID: stationID, fetchedAt: fetchedAt))
        try modelContext.save()
    }

    private func deleteExisting(stationID: String) throws {
        let extremeDescriptor = FetchDescriptor<CachedTideExtremeRecord>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        let heightDescriptor = FetchDescriptor<CachedTideHeightRecord>(
            predicate: #Predicate { $0.stationID == stationID }
        )
        let metadataDescriptor = FetchDescriptor<CachedTideMetadataRecord>(
            predicate: #Predicate { $0.stationID == stationID }
        )

        for record in try modelContext.fetch(extremeDescriptor) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(heightDescriptor) {
            modelContext.delete(record)
        }
        for record in try modelContext.fetch(metadataDescriptor) {
            modelContext.delete(record)
        }
    }
}