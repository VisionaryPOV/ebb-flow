import SwiftData
import SwiftUI

extension Notification.Name {
    static let ebbFlowRefreshTides = Notification.Name("ebbFlowRefreshTides")
    static let ebbFlowSetChartScale = Notification.Name("ebbFlowSetChartScale")
    static let ebbFlowExportCSV = Notification.Name("ebbFlowExportCSV")
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        AppRootContent(modelContext: modelContext)
    }
}

private struct AppRootContent: View {
    @State private var appModel: AppModel
    @State private var initialLoadStarted = false
    @State private var exportItem: TideExportItem?

    init(modelContext: ModelContext) {
        _appModel = State(wrappedValue: AppModel(modelContext: modelContext))
    }

    var body: some View {
        AdaptiveRootView(appModel: appModel)
            .onAppear {
                guard !initialLoadStarted else { return }
                initialLoadStarted = true
                Task { await appModel.loadDefaultStation() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ebbFlowRefreshTides)) { _ in
                Task { await appModel.loadDefaultStation() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ebbFlowSetChartScale)) { notification in
                guard let scale = notification.object as? ChartTimeScale else { return }
                Task { await appModel.setChartScale(scale) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .ebbFlowExportCSV)) { _ in
                presentCSVExport()
            }
            .sheet(item: $exportItem) { item in
                TideExportShareSheet(url: item.url)
            }
            .background(keyboardShortcutButtons)
    }

    private func presentCSVExport() {
        do {
            let url = try TideExporter.writeCSVFile(
                csv: appModel.exportCSV,
                stationID: appModel.selectedStation.id
            )
            exportItem = TideExportItem(url: url)
        } catch {
            appModel.errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private var keyboardShortcutButtons: some View {
        Group {
            Button("") { Task { await appModel.setChartScale(.day) } }
                .keyboardShortcut("1", modifiers: .command)
            Button("") { Task { await appModel.setChartScale(.week) } }
                .keyboardShortcut("2", modifiers: .command)
            Button("") { Task { await appModel.setChartScale(.month) } }
                .keyboardShortcut("3", modifiers: .command)
            Button("") { Task { await appModel.loadDefaultStation() } }
                .keyboardShortcut("r", modifiers: .command)
            Button("") { presentCSVExport() }
                .keyboardShortcut("e", modifiers: [.command, .shift])
        }
        .hidden()
    }
}