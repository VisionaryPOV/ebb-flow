import Foundation
import CoreLocation
import os
import SwiftData
import SwiftUI

enum TideExportKind: Sendable {
    case csv
    case pdf
}

@MainActor
@Observable
final class AppModel {
    private static let logger = Logger(subsystem: "com.ebbflow.app", category: "TideLoad")
    private static let maxLoadAttempts = 3
    private static let freeSpotLimit = 3

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
    let storeManager: StoreKitManager
    let stationMetadata: any NOAAStationFetching
    let locationService: any LocationProviding

    init(
        modelContext: ModelContext,
        selectedStation: TideStation? = nil,
        tideService: CompositeTideService? = nil,
        storeManager: StoreKitManager = StoreKitManager(),
        stationMetadata: (any NOAAStationFetching)? = nil,
        locationService: (any LocationProviding)? = nil
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
        self.storeManager = storeManager
        self.stationMetadata = stationMetadata ?? NOAAStationMetadataClient()
        self.locationService = locationService ?? LocationService()
        self.selectedStation = selectedStation ?? Self.stationFromPreferences()
        seedDefaultFavoriteIfNeeded(notify: false)
    }

    static func stationFromPreferences() -> TideStation {
        UserPreferencesStore.lastStation() ?? .marinaDelRey
    }

    func restoreLastStation() async {
        seedDefaultFavoriteIfNeeded(notify: true)
        _ = try? await stationMetadata.allStations()

        selectedStation = Self.stationFromPreferences()
        await load(station: selectedStation)
    }

    func loadDefaultStation() async {
        await load(station: selectedStation)
    }

    func selectStation(_ station: TideStation, favorite: Bool = false) async {
        if favorite {
            addFavoriteIfAllowed(station: station)
            notifySpotsChanged()
        }
        await load(station: station)
    }

    func selectStation(record: NOAAStationRecord, favorite: Bool = false) async {
        await selectStation(TideStationResolver.makeStation(from: record), favorite: favorite)
    }

    func selectNearestStation() async {
        do {
            let coordinate = try await locationService.currentCoordinate()
            let stations = try await stationMetadata.allStations()
            guard let nearest = NOAAStationDiscovery.nearest(stations: stations, to: coordinate).first else {
                errorMessage = "No tide stations found near your location."
                return
            }
            await selectStation(record: nearest.record)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
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
            UserPreferencesStore.saveLastStation(station)
            let display = displaySnapshot(from: loaded)
            SharedTideDataStore.write(display)
            if storeManager.canAccess(.liveActivities) {
                await LiveActivityCoordinator.publish(snapshot: display)
            }
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
        if scale == .month, !storeManager.canAccess(.monthlyCharts) {
            errorMessage = "Monthly charts require Ebb & Flow Pro."
            return
        }
        chartScale = scale
        await load(station: selectedStation)
    }

    func notifySpotsChanged() {
        spotsRevision += 1
    }

    var displayStationName: String {
        if let spot = try? spotsStore.spot(stationID: selectedStation.id) {
            return spot.name
        }
        return selectedStation.name
    }

    func toggleTableColumn(_ column: TideTableColumn) {
        if tableColumns.contains(column) {
            guard tableColumns.count > 1 else { return }
            tableColumns.remove(column)
        } else {
            tableColumns.insert(column)
        }
    }

    func exportFileURL(kind: TideExportKind) throws -> URL {
        guard storeManager.canAccess(.export) else {
            throw TideServiceError.invalidRequest
        }
        let timeZone = exportTimeZone
        switch kind {
        case .csv:
            return try TideExporter.writeCSVFile(csv: exportCSV(timeZone: timeZone), stationID: selectedStation.id)
        case .pdf:
            return try TideExporter.writePDFFile(
                rows: tableRows,
                stationName: displayStationName,
                stationID: selectedStation.id,
                columns: tableColumns,
                timeZone: timeZone
            )
        }
    }

    var stationCalendar: Calendar {
        var calendar = Calendar.current
        calendar.timeZone = exportTimeZone
        return calendar
    }

    var chartRange: ClosedRange<Date> {
        TideDateRangeCalculator.range(
            for: chartScale,
            containing: selectedChartDate,
            calendar: stationCalendar
        )
    }

    var personalOffsetFeet: Double {
        (try? spotsStore.spot(stationID: selectedStation.id)?.personalOffsetFeet) ?? 0
    }

    var exportTimeZone: TimeZone {
        TideStationCatalog.timeZone(for: selectedStation)
    }

    var displaySnapshot: TideSnapshot? {
        guard let snapshot else { return nil }
        return displaySnapshot(from: snapshot)
    }

    var filteredHeights: [TideHeight] {
        guard let displaySnapshot else { return [] }
        return TideDateRangeCalculator.filterHeights(displaySnapshot.heights, in: chartRange)
    }

    var filteredExtremes: [TideExtreme] {
        guard let displaySnapshot else { return [] }
        return TideDateRangeCalculator.filterExtremes(displaySnapshot.extremes, in: chartRange)
    }

    var tableRows: [TideTableRow] {
        TideTableBuilder.rows(from: filteredExtremes, columns: tableColumns)
    }

    func exportCSV(timeZone: TimeZone? = nil) -> String {
        TideExporter.csv(
            rows: tableRows,
            stationName: displayStationName,
            columns: tableColumns,
            timeZone: timeZone ?? exportTimeZone
        )
    }

    var exportCSV: String { exportCSV() }

    var exportPDF: Data {
        TideExporter.pdfData(
            rows: tableRows,
            stationName: displayStationName,
            columns: tableColumns,
            timeZone: exportTimeZone
        )
    }

    var lunarContext: (MoonPhase, SolarTimes, [TideEnergyWindow])? {
        guard let displaySnapshot else { return nil }
        let phase = LunarSolarEngine.moonPhase(for: selectedChartDate)
        let solar = LunarSolarEngine.solarTimes(
            for: selectedChartDate,
            latitude: selectedStation.latitude,
            longitude: selectedStation.longitude
        )
        let windows = LunarSolarEngine.tideEnergyWindows(extremes: displaySnapshot.extremes, solar: solar)
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
                addFavoriteIfAllowed(station: selectedStation)
            }
            notifySpotsChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addFavoriteIfAllowed(station: TideStation) {
        do {
            let count = try spotsStore.allSpots().count
            if count >= Self.freeSpotLimit, !storeManager.canAccess(.unlimitedSpots) {
                errorMessage = "Upgrade to Pro for unlimited favorite spots."
                return
            }
            try spotsStore.addSpot(for: station)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func seedDefaultFavoriteIfNeeded(notify: Bool) {
        guard UserPreferencesStore.needsDefaultFavoriteSeed else { return }
        do {
            if try !spotsStore.contains(stationID: TideStation.marinaDelRey.id) {
                try spotsStore.addSpot(for: .marinaDelRey)
                if notify { notifySpotsChanged() }
            }
            UserPreferencesStore.markDefaultFavoriteSeeded()
        } catch {
            NSLog("EbbFlow: Failed to seed default favorite %@", error.localizedDescription)
        }
    }

    func logJournalEntry(notes: String, photoPath: String = "") {
        guard let displaySnapshot else { return }
        let state = displaySnapshot.currentState
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
        displaySnapshot?.currentState ?? TideCurrentState(height: 0, isRising: false, nextExtreme: nil, coversReferenceDate: false)
    }

    private func displaySnapshot(from snapshot: TideSnapshot) -> TideSnapshot {
        let offset = (try? spotsStore.spot(stationID: snapshot.station.id)?.personalOffsetFeet) ?? 0
        return TideDisplayAdjuster.adjustedSnapshot(snapshot, offset: offset)
    }
}