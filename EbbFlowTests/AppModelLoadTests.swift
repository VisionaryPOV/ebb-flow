import Foundation
import SwiftData
import Testing
@testable import EbbFlow

@MainActor
struct AppModelLoadTests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            FavoriteSpot.self,
            CachedTideExtremeRecord.self,
            CachedTideHeightRecord.self,
            CachedTideMetadataRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func defaultStationLoadsMarinaDelReyData() async throws {
        let context = try makeContext()
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let referenceDate = Self.pacificCalendar.date(from: DateComponents(
            year: 2025, month: 6, day: 24, hour: 12
        ))!
        let cache = SwiftDataTideCache(modelContext: context)
        let service = CompositeTideService(
            client: fetcher,
            cache: cache,
            calendar: Self.pacificCalendar,
            now: { referenceDate }
        )

        let snapshot = try await service.loadTideData(for: .marinaDelRey)

        #expect(snapshot.station.id == "9410840")
        #expect(snapshot.station.name == "Marina del Rey")
        #expect(snapshot.extremes.count == 6)
        #expect(snapshot.heights.count == 17)
        #expect(snapshot.currentState.coversReferenceDate)
    }

    private static var pacificCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacific
        return calendar
    }
}