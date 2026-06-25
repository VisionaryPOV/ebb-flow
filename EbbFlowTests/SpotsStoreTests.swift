import Foundation
import SwiftData
import Testing
@testable import EbbFlow

@MainActor
struct SpotsStoreTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteSpot.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func addListRemoveSpotRoundtrip() throws {
        let context = try makeContext()
        let store = SpotsStore(modelContext: context)

        try store.addSpot(for: .marinaDelRey, notes: "Marina walk")
        #expect(try store.contains(stationID: "9410840"))

        let spots = try store.allSpots()
        #expect(spots.count == 1)
        #expect(spots.first?.name == "Marina del Rey")
        #expect(spots.first?.notes == "Marina walk")

        try store.removeSpot(stationID: "9410840")
        #expect(try store.contains(stationID: "9410840") == false)
        #expect(try store.allSpots().isEmpty)
    }

    @Test func renameSpotUpdatesDisplayName() throws {
        let context = try makeContext()
        let store = SpotsStore(modelContext: context)

        try store.addSpot(for: .marinaDelRey)
        try store.updateSpot(stationID: "9410840", name: "My Marina", notes: nil, photoPath: nil, personalOffsetFeet: nil)

        let spot = try #require(try store.spot(stationID: "9410840"))
        #expect(spot.name == "My Marina")
    }

    @Test func addDuplicateUpdatesNotes() throws {
        let context = try makeContext()
        let store = SpotsStore(modelContext: context)

        try store.addSpot(for: .marinaDelRey, notes: "First")
        try store.addSpot(for: .marinaDelRey, notes: "Updated")

        let spots = try store.allSpots()
        #expect(spots.count == 1)
        #expect(spots.first?.notes == "Updated")
    }
}