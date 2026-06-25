import Foundation
@testable import EbbFlow

struct FailingTideFetcher: TidePredictionFetching, Sendable {
    let error: TideServiceError

    init(error: TideServiceError = .networkFailure) {
        self.error = error
    }

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        throw error
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data {
        throw error
    }
}

actor RecordingTideFetcher: TidePredictionFetching {
    let response: Data
    private(set) var receivedStationIDs: [String] = []
    private(set) var receivedTimeZones: [TimeZone] = []

    init(response: Data) {
        self.response = response
    }

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        receivedStationIDs.append(stationID)
        receivedTimeZones.append(timeZone)
        return response
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data {
        receivedStationIDs.append(stationID)
        receivedTimeZones.append(timeZone)
        return response
    }
}