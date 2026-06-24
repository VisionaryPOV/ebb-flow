import Foundation
@testable import EbbFlow

struct FixtureTideFetcher: TidePredictionFetching, Sendable {
    let extremesData: Data
    let heightsData: Data

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        extremesData
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        heightsData
    }
}