import Foundation

enum ChartTimeScale: String, CaseIterable, Sendable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .day: "Today"
        case .week: "Week"
        case .month: "Month"
        }
    }

    var loadDays: Int {
        switch self {
        case .day: 2
        case .week: 7
        case .month: 30
        }
    }
}

enum TideDateRangeCalculator {
    static func dayRange(containing date: Date, calendar: Calendar = .current) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        return start...end
    }

    static func weekRange(containing date: Date, calendar: Calendar = .current) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? start
        return start...end
    }

    static func monthRange(containing date: Date, calendar: Calendar = .current) -> ClosedRange<Date> {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 30, to: start) ?? start
        return start...end
    }

    static func range(for scale: ChartTimeScale, containing date: Date, calendar: Calendar = .current) -> ClosedRange<Date> {
        switch scale {
        case .day: dayRange(containing: date, calendar: calendar)
        case .week: weekRange(containing: date, calendar: calendar)
        case .month: monthRange(containing: date, calendar: calendar)
        }
    }

    static func filterHeights(_ heights: [TideHeight], in range: ClosedRange<Date>) -> [TideHeight] {
        heights
            .filter { range.contains($0.time) }
            .sorted { $0.time < $1.time }
    }

    static func filterExtremes(_ extremes: [TideExtreme], in range: ClosedRange<Date>) -> [TideExtreme] {
        extremes
            .filter { range.contains($0.time) }
            .sorted { $0.time < $1.time }
    }
}