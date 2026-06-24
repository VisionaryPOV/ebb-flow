import Foundation

struct WidgetTideEntry: Sendable, Equatable {
    let date: Date
    let payload: SharedTideSnapshotPayload
    let refreshDate: Date
}

enum WidgetTimelineBuilder {
    static let refreshInterval: TimeInterval = 15 * 60

    static func entries(from payload: SharedTideSnapshotPayload, now: Date = Date()) -> [WidgetTideEntry] {
        let refresh = now.addingTimeInterval(refreshInterval)
        return [WidgetTideEntry(date: now, payload: payload, refreshDate: refresh)]
    }
}