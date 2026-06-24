import Foundation
@testable import EbbFlow

enum CancellingFixtureError: Error, LocalizedError {
    case cancelled

    var errorDescription: String? { "cancelled" }
}

actor CancellingOnceFixtureFetcher: TidePredictionFetching {
    let extremesData: Data
    let heightsData: Data
    private var didCancelOnce = false
    private(set) var fetchAttempts = 0

    init(extremesData: Data, heightsData: Data) {
        self.extremesData = extremesData
        self.heightsData = heightsData
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        fetchAttempts += 1
        if !didCancelOnce {
            didCancelOnce = true
            throw CancellingFixtureError.cancelled
        }
        return extremesData
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        return heightsData
    }
}