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
        MainTabView(appModel: appModel)
            .onAppear {
                guard !initialLoadStarted else { return }
                initialLoadStarted = true
                Task {
                    await appModel.loadDefaultStation()
                }
            }
    }
}

private struct MainTabView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView {
            Tab("Today", systemImage: "water.waves") {
                NavigationStack {
                    TodayView(appModel: appModel)
                }
            }

            Tab("Spots", systemImage: "mappin.and.ellipse") {
                NavigationStack {
                    SpotsView(appModel: appModel)
                }
            }

            Tab("More", systemImage: "ellipsis.circle") {
                NavigationStack {
                    MoreView()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            TideNowPlayingBar(
                stationName: appModel.selectedStation.name,
                state: appModel.currentState
            )
        }
    }
}