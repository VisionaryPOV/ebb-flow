#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct TideLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TideActivityAttributes.self) { context in
            TideLiveActivityLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.stationName)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(format: "%.1f ft", context.state.height))
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TideLiveActivityCountdownView(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "water.waves")
            } compactTrailing: {
                Text(String(format: "%.0f", context.state.height))
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "water.waves")
            }
        }
    }
}

struct TideLiveActivityLockScreenView: View {
    let state: TideActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(state.stationName)
                .font(.headline)
            Text(String(format: "%.1f ft · %@", state.height, state.isRising ? "Rising" : "Falling"))
                .font(.subheadline)
                .monospacedDigit()
            TideLiveActivityCountdownView(state: state)
        }
        .padding()
    }
}

struct TideLiveActivityCountdownView: View {
    let state: TideActivityAttributes.ContentState

    var body: some View {
        if let next = state.nextExtremeTime, next > Date() {
            HStack(spacing: 4) {
                Text(state.nextExtremeLabel)
                Text(timerInterval: Date()...next, countsDown: true)
            }
            .font(.caption)
            .monospacedDigit()
        } else {
            Text(state.nextExtremeLabel)
                .font(.caption)
        }
    }
}
#endif