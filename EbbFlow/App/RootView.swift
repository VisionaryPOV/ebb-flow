import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        AppRootContent(modelContext: modelContext)
    }
}

private struct AppRootContent: View {
    @State private var appModel: AppModel
    @State private var initialLoadStarted = false

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
    }
}