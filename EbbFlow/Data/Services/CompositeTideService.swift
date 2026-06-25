import Foundation

protocol TideCacheStoring: Sendable {
    func cachedExtremes(stationID: String) async -> [TideExtreme]?
    func cachedHeights(stationID: String) async -> [TideHeight]?
    func cachedFetchedAt(stationID: String) async -> Date?
    func store(
        extremes: [TideExtreme],
        heights: [TideHeight],
        stationID: String,
        fetchedAt: Date
    ) async throws
}

typealias DateProvider = @Sendable () -> Date

actor CompositeTideService {
    static let cacheTTL: TimeInterval = 6 * 60 * 60

    private let client: any TidePredictionFetching
    private let cache: any TideCacheStoring
    private let calendar: Calendar
    private let now: DateProvider

    init(
        client: any TidePredictionFetching,
        cache: any TideCacheStoring,
        calendar: Calendar = .current,
        now: @escaping DateProvider = { Date() }
    ) {
        self.client = client
        self.cache = cache
        self.calendar = calendar
        self.now = now
    }

    func loadTideData(
        for station: TideStation,
        days: Int = 2,
        forceRefresh: Bool = false
    ) async throws -> TideSnapshot {
        let referenceDate = now()
        let loadDays = max(days, 2)
        let timeZone = TideStationCatalog.timeZone(for: station)
        var stationCalendar = calendar
        stationCalendar.timeZone = timeZone

        if !forceRefresh,
           let cachedExtremes = await cache.cachedExtremes(stationID: station.id),
           let cachedHeights = await cache.cachedHeights(stationID: station.id),
           let fetchedAt = await cache.cachedFetchedAt(stationID: station.id),
           !cachedExtremes.isEmpty,
           !cachedHeights.isEmpty,
           isCacheValid(
               heights: cachedHeights,
               fetchedAt: fetchedAt,
               referenceDate: referenceDate,
               requiredDays: loadDays,
               calendar: stationCalendar
           ) {
            return TideSnapshot(
                station: station,
                extremes: cachedExtremes,
                heights: cachedHeights,
                fetchedAt: fetchedAt,
                referenceDate: referenceDate
            )
        }

        let start = stationCalendar.startOfDay(for: referenceDate)
        let end = stationCalendar.date(byAdding: .day, value: loadDays, to: start) ?? start

        let extremesData = try await client.fetchExtremes(
            stationID: station.id,
            from: start,
            to: end,
            timeZone: timeZone
        )
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData, timeZone: timeZone)

        let heights: [TideHeight]
        do {
            let heightsData = try await client.fetchHeights(
                stationID: station.id,
                from: start,
                to: end,
                intervalMinutes: 15,
                timeZone: timeZone
            )
            let parsed = try TideDataTransformer.parseHeights(from: heightsData, timeZone: timeZone)
            guard !parsed.isEmpty else { throw TideServiceError.parseFailure }
            heights = parsed
        } catch {
            heights = TideInterpolator.cosineHeights(
                from: extremes,
                start: start,
                end: end,
                step: 15 * 60
            )
            guard !heights.isEmpty else { throw error }
        }
        let fetchedAt = now()

        try await cache.store(
            extremes: extremes,
            heights: heights,
            stationID: station.id,
            fetchedAt: fetchedAt
        )

        return TideSnapshot(
            station: station,
            extremes: extremes,
            heights: heights,
            fetchedAt: fetchedAt,
            referenceDate: referenceDate
        )
    }

    func isCacheValid(
        heights: [TideHeight],
        fetchedAt: Date,
        referenceDate: Date,
        requiredDays: Int = 2,
        calendar: Calendar? = nil
    ) -> Bool {
        guard referenceDate.timeIntervalSince(fetchedAt) < Self.cacheTTL else {
            return false
        }

        let rangeCalendar = calendar ?? self.calendar
        let windowStart = rangeCalendar.startOfDay(for: referenceDate)
        let windowEnd = rangeCalendar.date(byAdding: .day, value: requiredDays, to: windowStart) ?? windowStart
        guard let dataStart = heights.map(\.time).min(),
              let dataEnd = heights.map(\.time).max() else {
            return false
        }

        return dataStart <= windowStart && dataEnd >= windowEnd
    }
}

struct TideSnapshot: Sendable, Equatable {
    let station: TideStation
    let extremes: [TideExtreme]
    let heights: [TideHeight]
    let fetchedAt: Date
    let referenceDate: Date

    init(
        station: TideStation,
        extremes: [TideExtreme],
        heights: [TideHeight],
        fetchedAt: Date,
        referenceDate: Date? = nil
    ) {
        self.station = station
        self.extremes = extremes
        self.heights = heights
        self.fetchedAt = fetchedAt
        self.referenceDate = referenceDate ?? fetchedAt
    }

    var currentState: TideCurrentState {
        TideDataTransformer.currentState(
            at: referenceDate,
            heights: heights,
            extremes: extremes
        )
    }
}