import Foundation
@testable import EbbFlow

struct FailingTideFetcher: TidePredictionFetching, Sendable {
    let error: TideServiceError

    init(error: TideServiceError = .networkFailure) {
        self.error = error
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        throw error
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        throw error
    }
}

actor RecordingTideFetcher: TidePredictionFetching {
    let response: Data
    private(set) var receivedStationIDs: [String] = []

    init(response: Data) {
        self.response = response
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        receivedStationIDs.append(stationID)
        return response
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        receivedStationIDs.append(stationID)
        return response
    }
}