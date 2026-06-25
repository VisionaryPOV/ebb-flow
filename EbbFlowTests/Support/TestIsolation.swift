import SwiftData
@testable import EbbFlow

enum TestIsolation {
    static func resetUserDefaultsAndCatalog() {
        UserPreferencesStore.resetAllForTesting()
        TideStationCatalog.clearRegistryForTesting()
    }

    @MainActor
    static func makeModelContext() throws -> ModelContext {
        let schema = Schema([
            FavoriteSpot.self,
            CachedTideExtremeRecord.self,
            CachedTideHeightRecord.self,
            CachedTideMetadataRecord.self,
            JournalEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}