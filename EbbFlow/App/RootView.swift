import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appModel: AppModel?

    var body: some View {
        Group {
            if let appModel {
                MainTabView(appModel: appModel)
            } else {
                ProgressView("Loading Ebb & Flow…")
                    .task {
                        appModel = AppModel(modelContext: modelContext)
                        await appModel?.loadDefaultStation()
                    }
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