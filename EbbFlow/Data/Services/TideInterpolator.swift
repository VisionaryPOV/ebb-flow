import Foundation

enum TideInterpolator {
    static func cosineHeights(
        from extremes: [TideExtreme],
        start: Date,
        end: Date,
        step: TimeInterval = 900
    ) -> [TideHeight] {
        guard extremes.count >= 2 else { return [] }

        let sorted = extremes.sorted { $0.time < $1.time }
        var results: [TideHeight] = []
        var current = start

        while current <= end {
            if let height = interpolatedHeight(at: current, extremes: sorted) {
                results.append(TideHeight(time: current, height: height))
            }
            current = current.addingTimeInterval(step)
        }

        return results
    }

    static func interpolatedHeight(at date: Date, extremes: [TideExtreme]) -> Double? {
        guard let first = extremes.first, let last = extremes.last else { return nil }
        if date <= first.time { return first.height }
        if date >= last.time { return last.height }

        guard let pair = adjacentExtremes(for: date, in: extremes) else { return nil }
        let (start, end) = pair
        let total = end.time.timeIntervalSince(start.time)
        guard total > 0 else { return start.height }

        let elapsed = date.timeIntervalSince(start.time)
        let phase = elapsed / total
        let midpoint = (start.height + end.height) / 2
        let amplitude = abs(end.height - start.height) / 2
        let direction: Double = end.kind == .high ? 1 : -1
        let cosine = cos(phase * .pi)
        return midpoint + direction * amplitude * cosine
    }

    private static func adjacentExtremes(
        for date: Date,
        in extremes: [TideExtreme]
    ) -> (TideExtreme, TideExtreme)? {
        for index in 0..<(extremes.count - 1) {
            let current = extremes[index]
            let next = extremes[index + 1]
            if date >= current.time && date <= next.time {
                return (current, next)
            }
        }
        return nil
    }
}