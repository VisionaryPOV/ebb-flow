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
    var chartScale: ChartTimeScale = .day
    var tableColumns: Set<TideTableColumn> = Set(TideTableColumn.allCases)
    private(set) var spotsRevision = 0

    private let tideService: CompositeTideService
    let spotsStore: SpotsStore
    let journalStore: JournalStore

    init(
        modelContext: ModelContext,
        selectedStation: TideStation = .marinaDelRey,
        tideService: CompositeTideService? = nil
    ) {
        if let tideService {
            self.tideService = tideService
        } else {
            let cache = SwiftDataTideCache(modelContext: modelContext)
            let client = CompositeTideProviderRouter()
            self.tideService = CompositeTideService(client: client, cache: cache)
        }
        self.spotsStore = SpotsStore(modelContext: modelContext)
        self.journalStore = JournalStore(modelContext: modelContext)
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
            let loaded = try await tideService.loadTideData(
                for: station,
                days: chartScale.loadDays
            )
            snapshot = loaded
            SharedTideDataStore.write(loaded)
            await LiveActivityCoordinator.publish(snapshot: loaded)
            Self.logger.info(
                "Loaded station \(station.id, privacy: .public) scale=\(self.chartScale.rawValue, privacy: .public) extremes=\(loaded.extremes.count, privacy: .public) heights=\(loaded.heights.count, privacy: .public)"
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
                try? await Task.sleep(nanoseconds: 250_000_000)
                await load(station: station, attempt: attempt + 1)
                return
            }
            errorMessage = error.localizedDescription
            NSLog("EbbFlow TideLoad: Failed station %@ error=%@", station.id, error.localizedDescription)
        }
    }

    func setChartScale(_ scale: ChartTimeScale) async {
        chartScale = scale
        await load(station: selectedStation)
    }

    var chartRange: ClosedRange<Date> {
        TideDateRangeCalculator.range(for: chartScale, containing: selectedChartDate)
    }

    var filteredHeights: [TideHeight] {
        guard let snapshot else { return [] }
        return TideDateRangeCalculator.filterHeights(snapshot.heights, in: chartRange)
    }

    var filteredExtremes: [TideExtreme] {
        guard let snapshot else { return [] }
        return TideDateRangeCalculator.filterExtremes(snapshot.extremes, in: chartRange)
    }

    var tableRows: [TideTableRow] {
        TideTableBuilder.rows(from: filteredExtremes, columns: tableColumns)
    }

    var exportCSV: String {
        TideExporter.csv(rows: tableRows, stationName: selectedStation.name, columns: tableColumns)
    }

    var exportPDF: Data {
        TideExporter.pdfData(rows: tableRows, stationName: selectedStation.name, columns: tableColumns)
    }

    var lunarContext: (MoonPhase, SolarTimes, [TideEnergyWindow])? {
        guard let snapshot else { return nil }
        let phase = LunarSolarEngine.moonPhase(for: selectedChartDate)
        let solar = LunarSolarEngine.solarTimes(
            for: selectedChartDate,
            latitude: selectedStation.latitude,
            longitude: selectedStation.longitude
        )
        let windows = LunarSolarEngine.tideEnergyWindows(extremes: snapshot.extremes, solar: solar)
        return (phase, solar, windows)
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
            spotsRevision += 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logJournalEntry(notes: String, photoPath: String = "") {
        guard let snapshot else { return }
        let state = snapshot.currentState
        do {
            try journalStore.addEntry(
                station: selectedStation,
                tideHeightFeet: state.height,
                tideKind: state.nextExtreme?.kind,
                notes: notes,
                photoPath: photoPath
            )
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