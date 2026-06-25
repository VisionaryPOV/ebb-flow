import Foundation

enum TideDataTransformer {
    /// NOAA `lst_ldt` responses use the station's local civil time.
    static let noaaLocalTimeZone = TimeZone(identifier: "America/Los_Angeles")!

    static func makePredictionDateFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }

    static func formatShortTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func formatMediumDateTime(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func parseExtremes(
        from data: Data,
        timeZone: TimeZone = noaaLocalTimeZone
    ) throws -> [TideExtreme] {
        let response = try JSONDecoder().decode(NOAAPredictionsResponse.self, from: data)
        let formatter = makePredictionDateFormatter(timeZone: timeZone)

        return response.predictions.compactMap { entry in
            guard let kindRaw = entry.type,
                  let kind = TideKind(rawValue: kindRaw),
                  let time = formatter.date(from: entry.t),
                  let height = Double(entry.v) else {
                return nil
            }
            return TideExtreme(time: time, height: height, kind: kind)
        }
        .sorted { $0.time < $1.time }
    }

    static func parseHeights(
        from data: Data,
        timeZone: TimeZone = noaaLocalTimeZone
    ) throws -> [TideHeight] {
        let response = try JSONDecoder().decode(NOAAPredictionsResponse.self, from: data)
        let formatter = makePredictionDateFormatter(timeZone: timeZone)

        return response.predictions.compactMap { entry in
            guard let time = formatter.date(from: entry.t),
                  let height = Double(entry.v) else {
                return nil
            }
            return TideHeight(time: time, height: height)
        }
        .sorted { $0.time < $1.time }
    }

    static func currentState(
        at date: Date,
        heights: [TideHeight],
        extremes: [TideExtreme]
    ) -> TideCurrentState {
        guard !heights.isEmpty else {
            return TideCurrentState(height: 0, isRising: false, nextExtreme: extremes.first, coversReferenceDate: false)
        }

        let sortedHeights = heights.sorted { $0.time < $1.time }
        let coversReferenceDate = sortedHeights.first!.time <= date && sortedHeights.last!.time >= date

        let nearest = sortedHeights.min { lhs, rhs in
            abs(lhs.time.timeIntervalSince(date)) < abs(rhs.time.timeIntervalSince(date))
        }
        let height = nearest?.height ?? sortedHeights.last?.height ?? 0

        let futureExtremes = extremes.filter { $0.time > date }.sorted { $0.time < $1.time }
        let nextExtreme = futureExtremes.first

        let isRising: Bool
        if let before = sortedHeights.last(where: { $0.time <= date }),
           let after = sortedHeights.first(where: { $0.time > date }) {
            isRising = after.height > before.height
        } else if let next = nextExtreme {
            isRising = next.kind == .high
        } else {
            isRising = false
        }

        return TideCurrentState(
            height: height,
            isRising: isRising,
            nextExtreme: nextExtreme,
            coversReferenceDate: coversReferenceDate
        )
    }
}

struct TideCurrentState: Sendable, Equatable {
    let height: Double
    let isRising: Bool
    let nextExtreme: TideExtreme?
    let coversReferenceDate: Bool

    init(
        height: Double,
        isRising: Bool,
        nextExtreme: TideExtreme?,
        coversReferenceDate: Bool = true
    ) {
        self.height = height
        self.isRising = isRising
        self.nextExtreme = nextExtreme
        self.coversReferenceDate = coversReferenceDate
    }
}