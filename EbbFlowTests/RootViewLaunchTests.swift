import Foundation
import Testing
@testable import EbbFlow

@MainActor
struct RootViewLaunchTests {
    @Test func appModelInitRestoresPersistedStationID() throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        UserPreferencesStore.saveLastStationID("9410840")

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

    @Test func appModelInitRestoresRegisteredHawaiiStation() throws {
        TestIsolation.resetUserDefaultsAndCatalog()
        let data = try FixtureLoader.data(named: "noaa_stations_sample")
        let stations = try JSONDecoder().decode(NOAAStationListResponse.self, from: data).stations
        TideStationCatalog.register(stations)
        UserPreferencesStore.saveLastStationID("1615202")

        let context = try TestIsolation.makeModelContext()
        let model = AppModel(modelContext: context)

        #expect(model.selectedStation.id == "1615202")
        #expect(model.selectedStation.name == "Makena")

        TestIsolation.resetUserDefaultsAndCatalog()
    }
}