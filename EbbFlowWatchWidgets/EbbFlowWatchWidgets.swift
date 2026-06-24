import SwiftUI
import WidgetKit

struct WatchTideEntry: TimelineEntry {
    let date: Date
    let height: Double
    let stationName: String
}

struct WatchTideProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchTideEntry {
        WatchTideEntry(date: Date(), height: 3.5, stationName: "Marina del Rey")
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchTideEntry) -> Void) {
        let timeline = WatchTimelineBuilder.complicationTimeline(from: SharedTideDataStore.read())
        completion(WatchTideEntry(
            date: timeline.entry.date,
            height: timeline.entry.height,
            stationName: timeline.entry.stationName
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchTideEntry>) -> Void) {
        let timeline = WatchTimelineBuilder.complicationTimeline(from: SharedTideDataStore.read())
        let entry = WatchTideEntry(
            date: timeline.entry.date,
            height: timeline.entry.height,
            stationName: timeline.entry.stationName
        )
        completion(Timeline(entries: [entry], policy: .after(timeline.refreshDate)))
    }
}

struct EbbFlowWatchComplication: Widget {
    let kind = "EbbFlowWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchTideProvider()) { entry in
            VStack {
                Text(entry.stationName).font(.caption2)
                Text(String(format: "%.1f ft", entry.height)).font(.title3).monospacedDigit()
            }
        }
        .configurationDisplayName("Tide")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular])
    }
}

@main
struct EbbFlowWatchWidgets: WidgetBundle {
    var body: some Widget {
        EbbFlowWatchComplication()
    }
}