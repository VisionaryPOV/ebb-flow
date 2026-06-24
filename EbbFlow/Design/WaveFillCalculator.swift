import Foundation
import SwiftUI

struct TideChartPoint: Sendable, Equatable, Identifiable {
    let id: UUID
    let time: Date
    let height: Double
    let normalizedY: Double

    init(id: UUID = UUID(), time: Date, height: Double, normalizedY: Double) {
        self.id = id
        self.time = time
        self.height = height
        self.normalizedY = normalizedY
    }
}

enum TideCurvePointGenerator {
    static func chartPoints(
        from heights: [TideHeight],
        in range: ClosedRange<Date>? = nil
    ) -> [TideChartPoint] {
        guard !heights.isEmpty else { return [] }

        let sorted = heights.sorted { $0.time < $1.time }
        let filtered: [TideHeight]
        if let range {
            filtered = sorted.filter { range.contains($0.time) }
        } else {
            filtered = sorted
        }
        guard !filtered.isEmpty else { return [] }

        let minHeight = filtered.map(\.height).min() ?? 0
        let maxHeight = filtered.map(\.height).max() ?? 1
        let span = max(maxHeight - minHeight, 0.001)

        return filtered.map { sample in
            let normalized = (sample.height - minHeight) / span
            return TideChartPoint(
                time: sample.time,
                height: sample.height,
                normalizedY: normalized
            )
        }
    }
}

enum WaveFillCalculator {
    static func fillLevel(
        currentHeight: Double,
        minHeight: Double,
        maxHeight: Double
    ) -> Double {
        let span = max(maxHeight - minHeight, 0.001)
        return min(max((currentHeight - minHeight) / span, 0), 1)
    }

    static func fillLevel(for heights: [TideHeight], at date: Date) -> Double {
        guard !heights.isEmpty else { return 0 }
        let minHeight = heights.map(\.height).min() ?? 0
        let maxHeight = heights.map(\.height).max() ?? 1
        let nearest = heights.min { lhs, rhs in
            abs(lhs.time.timeIntervalSince(date)) < abs(rhs.time.timeIntervalSince(date))
        }
        return fillLevel(
            currentHeight: nearest?.height ?? 0,
            minHeight: minHeight,
            maxHeight: maxHeight
        )
    }

    static func fillLevel(
        for heights: [TideHeight],
        at date: Date,
        in range: ClosedRange<Date>
    ) -> Double {
        let filtered = TideDateRangeCalculator.filterHeights(heights, in: range)
        return fillLevel(for: filtered, at: date)
    }

    static func weeklyWaveLevels(for heights: [TideHeight], in range: ClosedRange<Date>) -> [Double] {
        let filtered = TideDateRangeCalculator.filterHeights(heights, in: range)
        guard !filtered.isEmpty else { return [] }
        let minHeight = filtered.map(\.height).min() ?? 0
        let maxHeight = filtered.map(\.height).max() ?? 1
        return filtered.map {
            fillLevel(currentHeight: $0.height, minHeight: minHeight, maxHeight: maxHeight)
        }
    }
}

struct WaveLevelsVector: VectorArithmetic {
    var values: [Double]

    static var zero: WaveLevelsVector { WaveLevelsVector(values: []) }

    static func + (lhs: WaveLevelsVector, rhs: WaveLevelsVector) -> WaveLevelsVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: count)
        for index in 0..<count {
            let left = index < lhs.values.count ? lhs.values[index] : 0
            let right = index < rhs.values.count ? rhs.values[index] : 0
            result[index] = left + right
        }
        return WaveLevelsVector(values: result)
    }

    static func - (lhs: WaveLevelsVector, rhs: WaveLevelsVector) -> WaveLevelsVector {
        let count = max(lhs.values.count, rhs.values.count)
        var result = [Double](repeating: 0, count: count)
        for index in 0..<count {
            let left = index < lhs.values.count ? lhs.values[index] : 0
            let right = index < rhs.values.count ? rhs.values[index] : 0
            result[index] = left - right
        }
        return WaveLevelsVector(values: result)
    }

    mutating func scale(by rhs: Double) {
        values = values.map { $0 * rhs }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1 * $1 }
    }
}