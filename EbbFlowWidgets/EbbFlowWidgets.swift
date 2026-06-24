import SwiftUI
import WidgetKit

struct EbbFlowWidgetEntry: TimelineEntry {
    let date: Date
    let payload: SharedTideSnapshotPayload?
}

struct EbbFlowTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> EbbFlowWidgetEntry {
        EbbFlowWidgetEntry(date: Date(), payload: placeholderPayload)
    }

    func getSnapshot(in context: Context, completion: @escaping (EbbFlowWidgetEntry) -> Void) {
        completion(EbbFlowWidgetEntry(date: Date(), payload: SharedTideDataStore.read() ?? placeholderPayload))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EbbFlowWidgetEntry>) -> Void) {
        let payload = SharedTideDataStore.read() ?? placeholderPayload
        let entries = WidgetTimelineBuilder.entries(from: payload).map {
            EbbFlowWidgetEntry(date: $0.date, payload: $0.payload)
        }
        let refresh = payload.fetchedAt.addingTimeInterval(15 * 60)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private var placeholderPayload: SharedTideSnapshotPayload {
        SharedTideSnapshotPayload(
            stationID: "9410840",
            stationName: "Marina del Rey",
            currentHeight: 3.2,
            isRising: true,
            nextExtremeTime: Date().addingTimeInterval(3600),
            nextExtremeKind: "H",
            nextExtremeHeight: 5.1,
            fetchedAt: Date()
        )
    }
}

struct EbbFlowWidgetView: View {
    let entry: EbbFlowWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.payload?.stationName ?? "Ebb & Flow")
                .font(.headline)
            if let payload = entry.payload {
                Text(String(format: "%.1f ft", payload.currentHeight))
                    .font(family == .systemSmall ? .title2 : .largeTitle)
                    .monospacedDigit()
                Text(payload.isRising ? "Rising" : "Falling")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct EbbFlowWidgets: WidgetBundle {
    var body: some Widget {
        EbbFlowTideWidget()
        EbbFlowLockScreenWidget()
    }
}

struct EbbFlowTideWidget: Widget {
    let kind = "EbbFlowTideWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EbbFlowTimelineProvider()) { entry in
            EbbFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("Tide Now")
        .description("Current tide height and direction.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct EbbFlowLockScreenWidget: Widget {
    let kind = "EbbFlowLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EbbFlowTimelineProvider()) { entry in
            EbbFlowWidgetView(entry: entry)
        }
        .configurationDisplayName("Tide Glance")
        .description("Lock Screen tide glance.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}