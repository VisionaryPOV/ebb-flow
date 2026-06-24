import Foundation
@testable import EbbFlow

actor FixtureTideFetcher: TidePredictionFetching {
    let extremesData: Data
    let heightsData: Data
    private(set) var extremesFetchCount = 0
    private(set) var heightsFetchCount = 0

    init(extremesData: Data, heightsData: Data) {
        self.extremesData = extremesData
        self.heightsData = heightsData
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        extremesFetchCount += 1
        return extremesData
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        heightsFetchCount += 1
        return heightsData
    }

    var totalFetchCount: Int {
        extremesFetchCount + heightsFetchCount
    }
}