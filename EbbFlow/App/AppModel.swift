import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var selectedStation: TideStation
    var snapshot: TideSnapshot?
    var isLoading = false
    var errorMessage: String?
    var selectedChartDate = Date()

    private let tideService: CompositeTideService
    let spotsStore: SpotsStore

    init(modelContext: ModelContext, selectedStation: TideStation = .marinaDelRey) {
        let cache = SwiftDataTideCache(modelContext: modelContext)
        let client = NOAADataGetterClient()
        self.tideService = CompositeTideService(client: client, cache: cache)
        self.spotsStore = SpotsStore(modelContext: modelContext)
        self.selectedStation = selectedStation
    }

    func loadDefaultStation() async {
        await load(station: selectedStation)
    }

    func load(station: TideStation) async {
        selectedStation = station
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            snapshot = try await tideService.loadTideData(for: station)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite() {
        do {
            if try spotsStore.contains(stationID: selectedStation.id) {
                try spotsStore.removeSpot(stationID: selectedStation.id)
            } else {
                try spotsStore.addSpot(for: selectedStation)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isFavorite: Bool {
        (try? spotsStore.contains(stationID: selectedStation.id)) ?? false
    }

    var currentState: TideCurrentState {
        snapshot?.currentState ?? TideCurrentState(height: 0, isRising: false, nextExtreme: nil)
    }
}