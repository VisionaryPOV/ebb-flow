import Foundation
@testable import EbbFlow

actor FixtureTideFetcher: TidePredictionFetching {
    let extremesData: Data
    let heightsData: Data
    private(set) var extremesFetchCount = 0
    private(set) var heightsFetchCount = 0
    private(set) var receivedTimeZones: [TimeZone] = []

    init(extremesData: Data, heightsData: Data) {
        self.extremesData = extremesData
        self.heightsData = heightsData
    }

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        extremesFetchCount += 1
        receivedTimeZones.append(timeZone)
        return extremesData
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data {
        heightsFetchCount += 1
        receivedTimeZones.append(timeZone)
        return heightsData
    }

    var totalFetchCount: Int {
        extremesFetchCount + heightsFetchCount
    }
}