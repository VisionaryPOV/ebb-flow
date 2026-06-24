import Foundation
import SwiftData
import Testing
@testable import EbbFlow

struct Phase3Phase4Tests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    @Test func widgetTimelineBuilderProducesEntry() {
        let payload = SharedTideSnapshotPayload(
            stationID: "9410840",
            stationName: "Marina del Rey",
            currentHeight: 4.2,
            isRising: false,
            nextExtremeTime: Date(),
            nextExtremeKind: "L",
            nextExtremeHeight: 0.8,
            fetchedAt: Date()
        )
        let entries = WidgetTimelineBuilder.entries(from: payload)
        #expect(entries.count == 1)
        #expect(entries[0].payload.stationID == "9410840")
    }

    @Test func liveActivityTimelineEntryFromPayload() {
        let payload = SharedTideSnapshotPayload(
            stationID: "9410840",
            stationName: "Marina del Rey",
            currentHeight: 3.3,
            isRising: true,
            nextExtremeTime: nil,
            nextExtremeKind: nil,
            nextExtremeHeight: nil,
            fetchedAt: Date()
        )
        let entry = TideLiveActivityManager.timelineEntry(from: payload)
        #expect(entry.stationName == "Marina del Rey")
        #expect(entry.isRising)
    }

    @Test func lunarSolarMoonPhaseAndEnergyWindows() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.pacific
        let date = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let phase = LunarSolarEngine.moonPhase(for: date)
        #expect(MoonPhase.allCases.contains(phase))

        let solar = LunarSolarEngine.solarTimes(for: date, latitude: 33.97, longitude: -118.45, calendar: calendar)
        #expect(solar.sunset > solar.sunrise)

        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let windows = LunarSolarEngine.tideEnergyWindows(extremes: extremes, solar: solar, calendar: calendar)
        #expect(!windows.isEmpty)
    }

    @Test func worldTidesProviderRejectsWithoutAPIKey() async {
        let provider = WorldTidesProvider(apiKey: "")
        let result = provider.supports(latitude: 33.9, longitude: -118.4)
        #expect(result == false)
    }

    @Test func routerFallsBackThroughRealWorldTidesProvider() async throws {
        MockWorldTidesURLSessionFactory.reset()
        MockWorldTidesURLProtocol.responseData = Data("""
        {
          "status": 200,
          "heights": [
            {"dt": 1700000000, "height": 2.4},
            {"dt": 1700003600, "height": 2.8}
          ]
        }
        """.utf8)

        let worldTides = WorldTidesProvider(
            session: MockWorldTidesURLSessionFactory.make(),
            apiKey: "integration-test-key"
        )
        let router = CompositeTideProviderRouter(
            noaa: FailingTideFetcher(),
            worldTides: worldTides,
            catalogFallback: FailingTideFetcher(error: .cacheMiss)
        )

        let from = Date()
        let to = from.addingTimeInterval(86_400)
        let data = try await router.fetchHeights(
            stationID: "9410840",
            from: from,
            to: to,
            intervalMinutes: 15
        )

        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        #expect(heights.count == 2)
        #expect(MockWorldTidesURLProtocol.receivedURLs.count == 1)
        #expect(MockWorldTidesURLProtocol.receivedURLs[0].absoluteString.contains("lat=33.9767"))
        #expect(MockWorldTidesURLProtocol.receivedURLs[0].absoluteString.contains("lon=-118.4567"))
    }

    @Test func routerFallsBackToCatalogFixturesWithoutAPIKey() async throws {
        let router = CompositeTideProviderRouter(
            noaa: FailingTideFetcher(),
            worldTides: WorldTidesProvider(apiKey: ""),
            catalogFallback: CatalogTideFallbackProvider(loader: FixtureLoader.data(named:))
        )

        let from = Date()
        let to = from.addingTimeInterval(86_400)
        let data = try await router.fetchHeights(
            stationID: "9410840",
            from: from,
            to: to,
            intervalMinutes: 15
        )

        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        #expect(!heights.isEmpty)
    }

    @Test func worldTidesProviderParsesMockResponse() async throws {
        MockWorldTidesURLSessionFactory.reset()
        MockWorldTidesURLProtocol.responseData = Data("""
        {
          "status": 200,
          "heights": [{"dt": 1700000000, "height": 3.1}]
        }
        """.utf8)

        let provider = WorldTidesProvider(
            session: MockWorldTidesURLSessionFactory.make(),
            apiKey: "test-key"
        )
        let data = try await provider.fetchHeights(
            stationID: "33.9767,-118.4567",
            from: Date(),
            to: Date().addingTimeInterval(3600),
            intervalMinutes: 15
        )
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        #expect(heights.count == 1)
        #expect(heights[0].height == 3.1)
    }

    @Test func watchTimelineBuilderProducesEntry() {
        let payload = SharedTideSnapshotPayload(
            stationID: "9410840",
            stationName: "Marina del Rey",
            currentHeight: 2.8,
            isRising: true,
            nextExtremeTime: nil,
            nextExtremeKind: nil,
            nextExtremeHeight: nil,
            fetchedAt: Date()
        )
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = WatchTimelineBuilder.entry(from: payload, now: now)

        #expect(entry.stationName == "Marina del Rey")
        #expect(entry.height == 2.8)
        #expect(entry.date == now)
        #expect(entry.refreshDate == now.addingTimeInterval(900))
    }

    @Test func watchTimelineBuilderDefaultsWithoutPayload() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = WatchTimelineBuilder.entry(from: nil, now: now)

        #expect(entry.stationName == "Ebb & Flow")
        #expect(entry.height == 0)
    }

    @Test func watchComplicationTimelineMatchesProviderLogic() {
        let payload = SharedTideSnapshotPayload(
            stationID: "9410840",
            stationName: "Marina del Rey",
            currentHeight: 4.0,
            isRising: false,
            nextExtremeTime: nil,
            nextExtremeKind: nil,
            nextExtremeHeight: nil,
            fetchedAt: Date()
        )
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let timeline = WatchTimelineBuilder.complicationTimeline(from: payload, now: now)

        #expect(timeline.entry.stationName == "Marina del Rey")
        #expect(timeline.entry.height == 4.0)
        #expect(timeline.refreshDate == now.addingTimeInterval(WatchTimelineBuilder.refreshInterval))
    }

    @Test @MainActor func storeKitFeatureLabelsExist() {
        for feature in ProFeature.allCases {
            #expect(!StoreKitManager.featureLabel(feature).isEmpty)
        }
    }
}

@MainActor
struct SpotsDepthTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteSpot.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func spotsStorePersistsPhotoAndOffset() throws {
        let context = try makeContext()
        let store = SpotsStore(modelContext: context)

        try store.addSpot(
            for: .marinaDelRey,
            notes: "Sunset walk",
            photoPath: "9410840-photo.jpg",
            personalOffsetFeet: 0.5
        )

        let spot = try store.spot(stationID: "9410840")
        #expect(spot?.notes == "Sunset walk")
        #expect(spot?.photoPath == "9410840-photo.jpg")
        #expect(spot?.personalOffsetFeet == 0.5)
        #expect(spot?.adjustedHeight(3.0) == 3.5)
    }

    @Test func journalStoreAddsAndSearchesEntries() throws {
        let schema = Schema([JournalEntry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let store = JournalStore(modelContext: context)

        try store.addEntry(
            station: .marinaDelRey,
            tideHeightFeet: 4.2,
            tideKind: .high,
            notes: "Golden hour surf",
            photoPath: "journal-1.jpg"
        )

        let all = try store.allEntries()
        #expect(all.count == 1)
        #expect(all.first?.tideHeightFeet == 4.2)

        let search = try store.search(query: "golden")
        #expect(search.count == 1)
    }
}