import Foundation
import Testing
@testable import EbbFlow

private struct ExtremesOnlyFixtureFetcher: TidePredictionFetching, Sendable {
    let extremesData: Data

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        extremesData
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data {
        throw TideServiceError.parseFailure
    }
}

struct NOAAClientTests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private static var fixtureCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = pacific
        return calendar
    }

    private static var fixtureReferenceDate: Date {
        fixtureCalendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
    }

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

        let components = Self.fixtureCalendar.dateComponents([.hour, .minute], from: firstLow!.time)
        #expect(components.hour == 3)
        #expect(components.minute == 42)
    }

    @Test func parseMarinaDelReyHeightsFromFixture() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)

        #expect(heights.count == 17)
        #expect(heights.first?.height == 3.10)
        #expect(heights.contains { $0.height == 5.67 })
    }

    @Test func loadTideDataFetchesOnMissAndCaches() async throws {
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let cache = InMemoryTideCache()
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let referenceDate = Self.fixtureReferenceDate
        let service = CompositeTideService(
            client: fetcher,
            cache: cache,
            calendar: Self.fixtureCalendar,
            now: { referenceDate }
        )

        let snapshot = try await service.loadTideData(for: .marinaDelRey)

        #expect(snapshot.station.id == "9410840")
        #expect(snapshot.extremes.count == 6)
        #expect(snapshot.heights.count == 17)
        #expect(await fetcher.totalFetchCount == 2)

        let cachedFetchedAt = await cache.cachedFetchedAt(stationID: "9410840")
        #expect(cachedFetchedAt == referenceDate)
    }

    @Test func loadTideDataUsesCacheOnSecondCallWithoutRefetch() async throws {
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let cache = InMemoryTideCache()
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
        #expect(cachedSnapshot.fetchedAt == referenceDate)
        #expect(cachedSnapshot.extremes.count == 6)
        #expect(cachedSnapshot.currentState.coversReferenceDate)
    }

    @Test func loadTideDataRefetchesWhenCacheExpired() async throws {
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let cache = InMemoryTideCache()
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let referenceDate = Self.fixtureReferenceDate
        let staleDate = referenceDate.addingTimeInterval(CompositeTideService.cacheTTL + 60)
        let dateHolder = TestDateHolder(referenceDate)
        let service = CompositeTideService(
            client: fetcher,
            cache: cache,
            calendar: Self.fixtureCalendar,
            now: { dateHolder.value }
        )

        _ = try await service.loadTideData(for: .marinaDelRey)
        dateHolder.value = staleDate
        _ = try await service.loadTideData(for: .marinaDelRey)

        #expect(await fetcher.totalFetchCount == 4)
    }

    @Test func currentStateUsesParsedHeightsWithinDataWindow() throws {
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heights = try TideDataTransformer.parseHeights(from: heightsData, timeZone: Self.pacific)
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData, timeZone: Self.pacific)

        let sampleDate = Self.fixtureCalendar.date(from: DateComponents(
            year: 2025, month: 6, day: 24, hour: 10, minute: 0
        ))!

        let state = TideDataTransformer.currentState(
            at: sampleDate,
            heights: heights,
            extremes: extremes
        )

        #expect(state.height > 4.0)
        #expect(state.nextExtreme != nil)
        #expect(state.coversReferenceDate)
    }

    @Test func formatShortTimeUsesStationTimezoneNotDevice() throws {
        let hawaii = TimeZone(identifier: "Pacific/Honolulu")!
        let data = try FixtureLoader.data(named: "makena_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: hawaii)
        let first = try #require(extremes.first)

        let hawaiiLabel = TideDataTransformer.formatShortTime(first.time, timeZone: hawaii)
        let pacificLabel = TideDataTransformer.formatShortTime(first.time, timeZone: Self.pacific)
        #expect(hawaiiLabel != pacificLabel)
        #expect(hawaiiLabel.contains("2"))
    }

    @Test func validatePredictionsPayloadRejectsNOAAErrorJSON() throws {
        let errorJSON = Data("""
        {"error": {"message":"No Predictions data was found. Please make sure the Datum input is valid."}}
        """.utf8)

        #expect(throws: TideServiceError.parseFailure) {
            try NOAADataGetterClient.validatePredictionsPayload(errorJSON)
        }
    }

    @Test func loadTideDataSynthesizesHeightsWhenSubDailyUnavailable() async throws {
        let hawaii = TimeZone(identifier: "Pacific/Honolulu")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = hawaii
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 10))!
        let makena = TideStation(
            id: "1615202",
            name: "Makena",
            latitude: 20.6567,
            longitude: -156.445,
            datum: "MLLW",
            state: "HI"
        )
        let extremesData = try FixtureLoader.data(named: "makena_hilo")
        let fetcher = ExtremesOnlyFixtureFetcher(extremesData: extremesData)
        let cache = InMemoryTideCache()
        let service = CompositeTideService(
            client: fetcher,
            cache: cache,
            calendar: calendar,
            now: { referenceDate }
        )

        let snapshot = try await service.loadTideData(for: makena)

        #expect(snapshot.station.id == "1615202")
        #expect(snapshot.extremes.count == 6)
        #expect(!snapshot.heights.isEmpty)
        #expect(snapshot.currentState.coversReferenceDate)
        let components = calendar.dateComponents([.hour, .minute], from: snapshot.extremes.first!.time)
        #expect(components.hour == 2)
        #expect(components.minute == 12)
    }

    @Test func currentStateFlagsOutsideDataWindow() throws {
        let heightsData = try FixtureLoader.data(named: "marina_del_rey_heights")
        let extremesData = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let heights = try TideDataTransformer.parseHeights(from: heightsData, timeZone: Self.pacific)
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData, timeZone: Self.pacific)

        let outsideDate = Self.fixtureCalendar.date(from: DateComponents(
            year: 2026, month: 6, day: 23, hour: 12
        ))!

        let state = TideDataTransformer.currentState(
            at: outsideDate,
            heights: heights,
            extremes: extremes
        )

        #expect(state.coversReferenceDate == false)
    }
}