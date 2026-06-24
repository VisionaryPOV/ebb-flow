import Foundation
import Testing
@testable import EbbFlow

struct NOAAClientTests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    @Test func parseMarinaDelReyExtremesFromFixture() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)

        #expect(extremes.count == 6)

        let firstLow = extremes.first { $0.kind == .low }
        #expect(firstLow != nil)
        #expect(firstLow?.height == 0.82)

        let firstHigh = extremes.first { $0.kind == .high }
        #expect(firstHigh != nil)
        #expect(firstHigh?.height == 5.21)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.pacific
        let components = calendar.dateComponents([.hour, .minute], from: firstLow!.time)
        #expect(components.hour == 3)
        #expect(components.minute == 42)
    }

    @Test func parseMarinaDelReyHeightsFromFixture() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)

        #expect(heights.count == 11)
        #expect(heights.first?.height == 3.10)
        #expect(heights.contains { $0.height == 5.67 })
    }

    @Test func cacheRoundtripThroughCompositeService() async throws {
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let cache = InMemoryTideCache()
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let service = CompositeTideService(client: fetcher, cache: cache)

        let snapshot = try await service.loadTideDataFromFixture(
            station: .marinaDelRey,
            extremesData: extremesData,
            heightsData: heightsData
        )

        #expect(snapshot.station.id == "9410840")
        #expect(snapshot.extremes.count == 6)
        #expect(snapshot.heights.count == 11)

        let cachedExtremes = await cache.cachedExtremes(stationID: "9410840")
        let cachedHeights = await cache.cachedHeights(stationID: "9410840")
        #expect(cachedExtremes?.count == 6)
        #expect(cachedHeights?.count == 11)
        #expect(cachedExtremes?.first?.kind == .low)
    }

    @Test func currentStateUsesParsedHeights() throws {
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heights = try TideDataTransformer.parseHeights(from: heightsData, timeZone: Self.pacific)
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData, timeZone: Self.pacific)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.pacific
        let sampleDate = calendar.date(from: DateComponents(
            year: 2025, month: 6, day: 24, hour: 10, minute: 0
        ))!

        let state = TideDataTransformer.currentState(
            at: sampleDate,
            heights: heights,
            extremes: extremes
        )

        #expect(state.height > 4.0)
        #expect(state.nextExtreme != nil)
    }
}