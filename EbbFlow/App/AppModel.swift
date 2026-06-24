import Foundation
import os
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private static let logger = Logger(subsystem: "com.ebbflow.app", category: "TideLoad")
    private static let maxLoadAttempts = 3

    var selectedStation: TideStation
    var snapshot: TideSnapshot?
    var isLoading = false
    var errorMessage: String?
    var selectedChartDate = Date()

    private let tideService: CompositeTideService
    let spotsStore: SpotsStore

    init(
        modelContext: ModelContext,
        selectedStation: TideStation = .marinaDelRey,
        tideService: CompositeTideService? = nil
    ) {
        if let tideService {
            self.tideService = tideService
        } else {
            let cache = SwiftDataTideCache(modelContext: modelContext)
            let client = NOAADataGetterClient()
            self.tideService = CompositeTideService(client: client, cache: cache)
        }
        self.spotsStore = SpotsStore(modelContext: modelContext)
        self.selectedStation = selectedStation
    }

    func loadDefaultStation() async {
        await load(station: selectedStation)
    }

    func load(station: TideStation, attempt: Int = 1) async {
        selectedStation = station
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loaded = try await tideService.loadTideData(for: station)
            snapshot = loaded
            Self.logger.info(
                "Loaded default station \(station.id, privacy: .public) \(station.name, privacy: .public) extremes=\(loaded.extremes.count, privacy: .public) heights=\(loaded.heights.count, privacy: .public) fetchedAt=\(loaded.fetchedAt.timeIntervalSince1970, privacy: .public)"
            )
            NSLog(
                "EbbFlow TideLoad: Loaded station %@ (%@) extremes=%ld heights=%ld coversToday=%@",
                station.id,
                station.name,
                loaded.extremes.count,
                loaded.heights.count,
                loaded.currentState.coversReferenceDate ? "YES" : "NO"
            )
        } catch {
            if attempt < Self.maxLoadAttempts, Self.isTransientCancellation(error) {
                NSLog(
                    "EbbFlow TideLoad: Retrying station %@ after cancellation (attempt %ld)",
                    station.id,
                    attempt + 1
                )
                try? await Task.sleep(nanoseconds: 250_000_000)
                await load(station: station, attempt: attempt + 1)
                return
            }
            errorMessage = error.localizedDescription
            Self.logger.error("Failed to load station \(station.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            NSLog("EbbFlow TideLoad: Failed station %@ error=%@", station.id, error.localizedDescription)
        }
    }

    static func isTransientCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return true }
        return error.localizedDescription.lowercased().contains("cancelled")
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
        snapshot?.currentState ?? TideCurrentState(height: 0, isRising: false, nextExtreme: nil, coversReferenceDate: false)
    }
}