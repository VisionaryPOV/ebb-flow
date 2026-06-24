import Foundation
@testable import EbbFlow

actor InMemoryTideCache: TideCacheStoring {
    private var extremesByStation: [String: [TideExtreme]] = [:]
    private var heightsByStation: [String: [TideHeight]] = [:]
    private var fetchedAtByStation: [String: Date] = [:]

    func cachedExtremes(stationID: String) async -> [TideExtreme]? {
        extremesByStation[stationID]
    }

    func cachedHeights(stationID: String) async -> [TideHeight]? {
        heightsByStation[stationID]
    }

    func cachedFetchedAt(stationID: String) async -> Date? {
        fetchedAtByStation[stationID]
    }

    func store(
        extremes: [TideExtreme],
        heights: [TideHeight],
        stationID: String,
        fetchedAt: Date
    ) async throws {
        extremesByStation[stationID] = extremes
        heightsByStation[stationID] = heights
        fetchedAtByStation[stationID] = fetchedAt
    }
}