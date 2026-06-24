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
        let built = WatchTimelineBuilder.entry(from: SharedTideDataStore.read())
        completion(WatchTideEntry(
            date: built.date,
            height: built.height,
            stationName: built.stationName
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchTideEntry>) -> Void) {
        let built = WatchTimelineBuilder.entry(from: SharedTideDataStore.read())
        let entry = WatchTideEntry(
            date: built.date,
            height: built.height,
            stationName: built.stationName
        )
        completion(Timeline(entries: [entry], policy: .after(built.refreshDate)))
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
struct EbbFlowWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
    }
}

struct WatchRootView: View {
    var body: some View {
        let payload = SharedTideDataStore.read()
        VStack(spacing: 8) {
            Text(payload?.stationName ?? "Ebb & Flow").font(.headline)
            Text(String(format: "%.1f ft", payload?.currentHeight ?? 0))
                .font(.largeTitle)
                .monospacedDigit()
            Text(payload?.isRising == true ? "Rising" : "Falling")
                .foregroundStyle(.secondary)
        }
    }
}