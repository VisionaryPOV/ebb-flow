import Foundation
import Testing
@testable import EbbFlow

@MainActor
struct RootViewLaunchTests {
    private static let makena = TideStation(
        id: "1615202",
        name: "Makena",
        latitude: 20.6567,
        longitude: -156.445,
        datum: "MLLW"
    )

    @Test func appModelInitRestoresPersistedStationID() throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        UserPreferencesStore.saveLastStation(.marinaDelRey)

        let context = try TestIsolation.makeModelContext()
        let model = AppModel(modelContext: context)

        #expect(model.selectedStation.id == "9410840")
        #expect(model.selectedStation.name == "Marina del Rey")
        #expect(model.spotsRevision == 0)

        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @Test func appModelInitDefaultsToMarinaWhenNoPersistence() throws {
        TestIsolation.resetUserDefaultsAndCatalog()

        let context = try TestIsolation.makeModelContext()
        let model = AppModel(modelContext: context)

        #expect(model.selectedStation.id == TideStation.marinaDelRey.id)
        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @Test func appModelInitRestoresPersistedHawaiiStationWithoutCatalog() throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        TideStationCatalog.clearRegistryForTesting()
        UserPreferencesStore.saveLastStation(Self.makena)

        let context = try TestIsolation.makeModelContext()
        let model = AppModel(modelContext: context)

        #expect(model.selectedStation.id == "1615202")
        #expect(model.selectedStation.name == "Makena")
        #expect(model.selectedStation.latitude == 20.6567)

        TestIsolation.resetUserDefaultsAndCatalog()
    }

    @Test func coldStartRestoreLastStationLoadsPersistedHawaiiTides() async throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        TideStationCatalog.clearRegistryForTesting()
        UserPreferencesStore.saveLastStation(Self.makena)

        let extremesData = try FixtureLoader.data(named: "makena_hilo")
        let heightsData = try FixtureLoader.data(named: "makena_heights")
        let tideFetcher = FixtureTideFetcher(extremesData: extremesData, heightsData: heightsData)
        let metadata = FixtureNOAAStationFetcher(stations: [])

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Pacific/Honolulu")!
        let referenceDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 10))!
        let context = try TestIsolation.makeModelContext()
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
            stationMetadata: metadata
        )

        #expect(model.selectedStation.id == "1615202")

        await model.restoreLastStation()

        #expect(model.selectedStation.id == "1615202")
        #expect(model.selectedStation.name == "Makena")
        #expect(model.snapshot != nil)
        #expect(model.snapshot?.extremes.isEmpty == false)

        TestIsolation.resetUserDefaultsAndCatalog()
    }
}