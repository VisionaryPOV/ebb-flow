import AppIntents
import Foundation

struct GetTideIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Tide"
    static let description = IntentDescription("Get the current tide for Marina del Rey.")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let payload = SharedTideDataStore.read()
        if let payload {
            let direction = payload.isRising ? "rising" : "falling"
            return .result(value: "\(payload.stationName): \(String(format: "%.1f", payload.currentHeight)) ft, \(direction)")
        }
        return .result(value: "No tide data available")
    }
}

struct EbbFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTideIntent(),
            phrases: [
                "Get tide in \(.applicationName)",
                "What's the tide with \(.applicationName)"
            ],
            shortTitle: "Get Tide",
            systemImageName: "water.waves"
        )
    }
}