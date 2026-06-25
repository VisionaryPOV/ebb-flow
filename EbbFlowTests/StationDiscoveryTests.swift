import CoreLocation
import Foundation
import SwiftData
import Testing
@testable import EbbFlow

struct StationDiscoveryTests {
    private static let hawaii = TimeZone(identifier: "Pacific/Honolulu")!
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private func sampleStations() throws -> [NOAAStationRecord] {
        let data = try FixtureLoader.data(named: "noaa_stations_sample")
        return try JSONDecoder().decode(NOAAStationListResponse.self, from: data).stations
    }

    @Test func filterFindsMarinaAndMauiStations() throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        let stations = try sampleStations()
        let marina = NOAAStationDiscovery.filter(stations: stations, query: "Marina")
        #expect(marina.contains(where: { $0.id == "9410840" }))

        let maui = NOAAStationDiscovery.filter(stations: stations, query: "Maui")
        #expect(maui.contains(where: { $0.id == "1615680" }))
        #expect(maui.contains(where: { $0.id == "1615202" }))
    }

    @Test func nearestFindsMakenaNearMcKennaBeach() throws {
        let stations = try sampleStations()
        let mckenna = CLLocationCoordinate2D(latitude: 20.653, longitude: -156.442)
        let nearest = NOAAStationDiscovery.nearest(stations: stations, to: mckenna, limit: 1)
        #expect(nearest.count == 1)
        #expect(nearest.first?.record.id == "1615202")
        #expect(nearest.first!.distanceMeters < 2_000)
    }

    @Test func timeZoneUsesHawaiiForMakena() throws {
        let stations = try sampleStations()
        let makena = try #require(stations.first(where: { $0.id == "1615202" }))
        let tz = NOAAStationDiscovery.timeZone(for: makena)
        #expect(tz.identifier == Self.hawaii.identifier)
    }

    @Test func timeZoneUsesPacificForMarinaDelRey() throws {
        let stations = try sampleStations()
        let marina = try #require(stations.first(where: { $0.id == "9410840" }))
        let tz = NOAAStationDiscovery.timeZone(for: marina)
        #expect(tz.identifier == Self.pacific.identifier)
    }

    @Test func parseMakenaExtremesWithHawaiiTimeZone() throws {
        let data = try FixtureLoader.data(named: "makena_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.hawaii)
        #expect(!extremes.isEmpty)

        let formatter = TideDataTransformer.makePredictionDateFormatter(timeZone: Self.hawaii)
        let first = try #require(extremes.first)
        let components = Calendar(identifier: .gregorian).dateComponents(in: Self.hawaii, from: first.time)
        #expect(components.hour == 2)
        #expect(components.minute == 12)

        let roundTrip = formatter.string(from: first.time)
        #expect(roundTrip.hasPrefix("2025-06-24"))
    }

    @Test func catalogResolvesArbitraryRegisteredStation() throws {
        let stations = try sampleStations()
        TideStationCatalog.register(stations)
        let resolved = try #require(TideStationCatalog.resolve(id: "1615202"))
        #expect(resolved.name == "Makena")
        #expect(resolved.latitude == 20.6567)
    }

    @Test func compositeServiceLoadsMakenaWithHawaiiTimezone() async throws {
        let extremesData = try FixtureLoader.data(named: "makena_hilo")
        let heightsData = try FixtureLoader.data(named: "makena_heights")
        let fetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let stations = try sampleStations()
        TideStationCatalog.register(stations)
        let makena = TideStationResolver.makeStation(from: try #require(stations.first(where: { $0.id == "1615202" })))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.hawaii
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 10))!
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
        #expect(snapshot.heights.count == 17)
        #expect(TideStationCatalog.timeZone(for: makena).identifier == Self.hawaii.identifier)
    }

    @Test func userPreferencesRoundtrip() {
        TestIsolation.resetUserDefaultsAndCatalog()
        TideStationCatalog.clearRegistryForTesting()
        #expect(UserPreferencesStore.lastStation() == nil)
        #expect(UserPreferencesStore.needsDefaultFavoriteSeed)

        let makena = TideStation(
            id: "1615202",
            name: "Makena",
            latitude: 20.6567,
            longitude: -156.445,
            datum: "MLLW",
            state: "HI"
        )
        UserPreferencesStore.saveLastStation(makena)
        let restored = UserPreferencesStore.lastStation()
        #expect(restored?.id == "1615202")
        #expect(restored?.name == "Makena")
        #expect(restored?.state == "HI")
        TideStationCatalog.clearRegistryForTesting()
        #expect(TideStationCatalog.timeZone(for: restored!).identifier == Self.hawaii.identifier)

        UserPreferencesStore.markDefaultFavoriteSeeded()
        #expect(UserPreferencesStore.needsDefaultFavoriteSeed == false)
        TestIsolation.resetUserDefaultsAndCatalog()
        #expect(UserPreferencesStore.needsDefaultFavoriteSeed)
    }

    @MainActor
    @Test func restoreLastStationUsesPersistedID() async throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        TideStationCatalog.clearRegistryForTesting()
        let stations = try sampleStations()
        let makena = TideStationResolver.makeStation(from: try #require(stations.first(where: { $0.id == "1615202" })))
        UserPreferencesStore.saveLastStation(makena)

        let fetcher = FixtureNOAAStationFetcher(stations: stations)
        let extremesData = try FixtureLoader.data(named: "makena_hilo")
        let heightsData = try FixtureLoader.data(named: "makena_heights")
        let tideFetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.hawaii
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 10))!
        let context = try makeContext()
        let cache = SwiftDataTideCache(modelContext: context)
        let service = CompositeTideService(
            client: tideFetcher,
            cache: cache,
            calendar: calendar,
            now: { referenceDate }
        )
        let model = AppModel(
            modelContext: context,
            tideService: service,
            stationMetadata: fetcher
        )

        #expect(model.selectedStation.id == "1615202")
        #expect(TideStationCatalog.timeZone(for: model.selectedStation).identifier == Self.hawaii.identifier)

        await model.restoreLastStation()

        #expect(model.selectedStation.id == "1615202")
        #expect(model.snapshot != nil)
        let components = calendar.dateComponents([.hour], from: try #require(model.snapshot?.extremes.first?.time))
        #expect(components.hour == 2)
        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @Test func timeZoneForHawaiiStationWithoutRegistry() {
        TestIsolation.resetUserDefaultsAndCatalog()
        TideStationCatalog.clearRegistryForTesting()
        let makena = TideStation(
            id: "1615202",
            name: "Makena",
            latitude: 20.6567,
            longitude: -156.445,
            datum: "MLLW",
            state: "HI"
        )
        #expect(TideStationCatalog.timeZone(for: makena).identifier == Self.hawaii.identifier)
        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @MainActor
    @Test func renameFavoriteUpdatesDisplayName() throws {
        let context = try makeContext()
        let store = SpotsStore(modelContext: context)
        let stations = try sampleStations()
        TideStationCatalog.register(stations)
        let makena = TideStationResolver.makeStation(from: try #require(stations.first(where: { $0.id == "1615202" })))

        try store.addSpot(for: makena)
        try store.updateSpot(stationID: "1615202", name: "McKenna Beach", notes: nil, photoPath: nil, personalOffsetFeet: nil)

        let spot = try #require(try store.spot(stationID: "1615202"))
        #expect(spot.name == "McKenna Beach")
        #expect(spot.station.name == "McKenna Beach")
    }

    @MainActor
    @Test func selectNearestUsesMockLocation() async throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        let stations = try sampleStations()
        let metadata = FixtureNOAAStationFetcher(stations: stations)
        let mckenna = CLLocationCoordinate2D(latitude: 20.653, longitude: -156.442)
        let location = MockLocationService(coordinate: mckenna)

        let extremesData = try FixtureLoader.data(named: "makena_hilo")
        let heightsData = try FixtureLoader.data(named: "makena_heights")
        let tideFetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.hawaii
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 10))!
        let context = try makeContext()
        let cache = SwiftDataTideCache(modelContext: context)
        let service = CompositeTideService(
            client: tideFetcher,
            cache: cache,
            calendar: calendar,
            now: { referenceDate }
        )
        let model = AppModel(
            modelContext: context,
            tideService: service,
            stationMetadata: metadata,
            locationService: location
        )

        await model.selectNearestStation()

        #expect(model.selectedStation.id == "1615202")
        #expect(model.snapshot != nil)
        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        try TestIsolation.makeModelContext()
    }
}