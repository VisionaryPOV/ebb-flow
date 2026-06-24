import Foundation
@testable import EbbFlow

actor InMemoryTideCache: TideCacheStoring {
    private var extremesByStation: [String: [TideExtreme]] = [:]
    private var heightsByStation: [String: [TideHeight]] = [:]

    func cachedExtremes(stationID: String) async -> [TideExtreme]? {
        extremesByStation[stationID]
    }

    func cachedHeights(stationID: String) async -> [TideHeight]? {
        heightsByStation[stationID]
    }

    func store(extremes: [TideExtreme], heights: [TideHeight], stationID: String) async throws {
        extremesByStation[stationID] = extremes
        heightsByStation[stationID] = heights
    }
}