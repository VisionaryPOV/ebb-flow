import Foundation
import SwiftData
import Testing
@testable import EbbFlow

@MainActor
struct SwiftDataTideCacheTests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private static var fixtureCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacific
        return calendar
    }

    private static var fixtureReferenceDate: Date {
        fixtureCalendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            CachedTideExtremeRecord.self,
            CachedTideHeightRecord.self,
            CachedTideMetadataRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func swiftDataCacheRoundtripPreservesFetchedAt() async throws {
        let context = try makeContext()
        let cache = SwiftDataTideCache(modelContext: context)
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData, timeZone: Self.pacific)
        let heights = try TideDataTransformer.parseHeights(from: heightsData, timeZone: Self.pacific)
        let fetchedAt = Self.fixtureReferenceDate

        try await cache.store(
            extremes: extremes,
            heights: heights,
            stationID: "9410840",
            fetchedAt: fetchedAt
        )

        let cachedExtremes = await cache.cachedExtremes(stationID: "9410840")
        let cachedHeights = await cache.cachedHeights(stationID: "9410840")
        let cachedFetchedAt = await cache.cachedFetchedAt(stationID: "9410840")

        #expect(cachedExtremes?.count == 6)
        #expect(cachedHeights?.count == 17)
        #expect(cachedFetchedAt == fetchedAt)
        #expect(cachedExtremes?.first?.kind == .low)
    }

    @Test func compositeServiceUsesSwiftDataCacheOnSecondLoad() async throws {
        let context = try makeContext()
        let cache = SwiftDataTideCache(modelContext: context)
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let referenceDate = Self.fixtureReferenceDate
        let service = CompositeTideService(
            client: fetcher,
            cache: cache,
            calendar: Self.fixtureCalendar,
            now: { referenceDate }
        )

        _ = try await service.loadTideData(for: .marinaDelRey)
        let cachedSnapshot = try await service.loadTideData(for: .marinaDelRey)

        #expect(await fetcher.totalFetchCount == 2)
        #expect(cachedSnapshot.station.id == "9410840")
        #expect(cachedSnapshot.extremes.count == 6)
        #expect(cachedSnapshot.heights.count == 17)
        #expect(cachedSnapshot.fetchedAt == referenceDate)
        #expect(cachedSnapshot.currentState.coversReferenceDate)
    }
}