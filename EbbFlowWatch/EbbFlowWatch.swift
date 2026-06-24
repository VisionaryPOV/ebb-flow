import SwiftUI

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
        let built = WatchTimelineBuilder.entry(from: SharedTideDataStore.read())
        VStack(spacing: 8) {
            Text(built.stationName).font(.headline)
            Text(String(format: "%.1f ft", built.height))
                .font(.largeTitle)
                .monospacedDigit()
            Text(SharedTideDataStore.read()?.isRising == true ? "Rising" : "Falling")
                .foregroundStyle(.secondary)
        }
    }
}