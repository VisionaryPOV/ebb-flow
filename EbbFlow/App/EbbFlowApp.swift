import SwiftData
import SwiftUI

@main
struct EbbFlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteSpot.self,
            CachedTideExtremeRecord.self,
            CachedTideHeightRecord.self,
            CachedTideMetadataRecord.self,
            JournalEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandMenu("Chart") {
                Button("Today") {
                    NotificationCenter.default.post(name: .ebbFlowSetChartScale, object: ChartTimeScale.day)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Week") {
                    NotificationCenter.default.post(name: .ebbFlowSetChartScale, object: ChartTimeScale.week)
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("Month") {
                    NotificationCenter.default.post(name: .ebbFlowSetChartScale, object: ChartTimeScale.month)
                }
                .keyboardShortcut("3", modifiers: .command)
            }

            CommandGroup(after: .saveItem) {
                Button("Refresh Tides") {
                    NotificationCenter.default.post(name: .ebbFlowRefreshTides, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)

                Button("Export CSV") {
                    NotificationCenter.default.post(name: .ebbFlowExportCSV, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Export PDF") {
                    NotificationCenter.default.post(name: .ebbFlowExportPDF, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}