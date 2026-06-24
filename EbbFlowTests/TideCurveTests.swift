import Foundation
import Testing
@testable import EbbFlow

struct TideCurveTests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    @Test func chartPointsNormalizeBetweenZeroAndOne() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        let points = TideCurvePointGenerator.chartPoints(from: heights)

        #expect(points.count == heights.count)
        #expect(points.map(\.normalizedY).min() == 0)
        #expect(points.map(\.normalizedY).max() == 1)
        #expect(points.contains { $0.height == 5.67 })
    }

    @Test func waveFillLevelTracksCurrentHeight() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.pacific
        let date = calendar.date(from: DateComponents(
            year: 2025, month: 6, day: 24, hour: 22, minute: 9
        ))!

        let fill = WaveFillCalculator.fillLevel(for: heights, at: date)
        #expect(fill > 0.9)
    }

    @Test func interpolatorProducesSmoothSeries() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.pacific
        let start = calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 0))!
        let end = calendar.date(from: DateComponents(year: 2025, month: 6, day: 25, hour: 0))!

        let interpolated = TideInterpolator.cosineHeights(
            from: extremes,
            start: start,
            end: end,
            step: 900
        )

        #expect(interpolated.count > 10)
        #expect(interpolated.allSatisfy { $0.height.isFinite })
    }
}