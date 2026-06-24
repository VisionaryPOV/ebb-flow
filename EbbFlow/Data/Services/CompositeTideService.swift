import Foundation

protocol TideCacheStoring: Sendable {
    func cachedExtremes(stationID: String) async -> [TideExtreme]?
    func cachedHeights(stationID: String) async -> [TideHeight]?
    func store(extremes: [TideExtreme], heights: [TideHeight], stationID: String) async throws
}

actor CompositeTideService {
    private let client: any TidePredictionFetching
    private let cache: any TideCacheStoring
    private let calendar: Calendar

    init(
        client: any TidePredictionFetching,
        cache: any TideCacheStoring,
        calendar: Calendar = .current
    ) {
        self.client = client
        self.cache = cache
        self.calendar = calendar
    }

    func loadTideData(for station: TideStation) async throws -> TideSnapshot {
        if let cachedExtremes = await cache.cachedExtremes(stationID: station.id),
           let cachedHeights = await cache.cachedHeights(stationID: station.id),
           !cachedExtremes.isEmpty,
           !cachedHeights.isEmpty {
            return TideSnapshot(
                station: station,
                extremes: cachedExtremes,
                heights: cachedHeights,
                fetchedAt: Date()
            )
        }

        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 2, to: start) ?? start

        let extremesData = try await client.fetchExtremes(
            stationID: station.id,
            from: start,
            to: end
        )
        let heightsData = try await client.fetchHeights(
            stationID: station.id,
            from: start,
            to: end,
            intervalMinutes: 15
        )

        let extremes = try TideDataTransformer.parseExtremes(from: extremesData)
        let heights = try TideDataTransformer.parseHeights(from: heightsData)

        try await cache.store(extremes: extremes, heights: heights, stationID: station.id)

        return TideSnapshot(
            station: station,
            extremes: extremes,
            heights: heights,
            fetchedAt: Date()
        )
    }

    func loadTideDataFromFixture(
        station: TideStation,
        extremesData: Data,
        heightsData: Data
    ) async throws -> TideSnapshot {
        let extremes = try TideDataTransformer.parseExtremes(from: extremesData)
        let heights = try TideDataTransformer.parseHeights(from: heightsData)
        try await cache.store(extremes: extremes, heights: heights, stationID: station.id)
        return TideSnapshot(
            station: station,
            extremes: extremes,
            heights: heights,
            fetchedAt: Date()
        )
    }
}

struct TideSnapshot: Sendable, Equatable {
    let station: TideStation
    let extremes: [TideExtreme]
    let heights: [TideHeight]
    let fetchedAt: Date

    var currentState: TideCurrentState {
        TideDataTransformer.currentState(
            at: Date(),
            heights: heights,
            extremes: extremes
        )
    }
}