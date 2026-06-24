import SwiftUI

struct AdaptiveRootView: View {
    @Bindable var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadSplitView(appModel: appModel)
        } else {
            phoneTabView(appModel: appModel)
        }
    }
}

private struct iPadSplitView: View {
    @Bindable var appModel: AppModel
    @State private var spots: [FavoriteSpot] = []

    var body: some View {
        NavigationSplitView {
            List(selection: Binding(
                get: { appModel.selectedStation.id },
                set: { id in
                    if let spot = spots.first(where: { $0.stationID == id }) {
                        Task { await appModel.load(station: spot.station) }
                    }
                }
            )) {
                Section("Current") {
                    NavigationLink(value: appModel.selectedStation.id) {
                        Text(appModel.selectedStation.name)
                    }
                }
                Section("My Spots") {
                    ForEach(spots, id: \.stationID) { spot in
                        NavigationLink(value: spot.stationID) { Text(spot.name) }
                    }
                }
            }
            .navigationTitle("Stations")
            .task { spots = (try? appModel.spotsStore.allSpots()) ?? [] }
        } detail: {
            NavigationStack {
                TodayView(appModel: appModel)
            }
        }
        #if os(iOS)
        .keyboardShortcut("1", modifiers: .command)
        #endif
    }
}

private struct phoneTabView: View {
    @Bindable var appModel: AppModel

    var body: some View {
        TabView {
            Tab("Today", systemImage: "water.waves") {
                NavigationStack { TodayView(appModel: appModel) }
            }
            Tab("Spots", systemImage: "mappin.and.ellipse") {
                NavigationStack { SpotsView(appModel: appModel) }
            }
            Tab("Map", systemImage: "map") {
                NavigationStack { StationMapView(station: appModel.selectedStation) }
            }
            Tab("Journal", systemImage: "book.closed") {
                NavigationStack { JournalView(appModel: appModel) }
            }
            Tab("More", systemImage: "ellipsis.circle") {
                NavigationStack { MoreView(storeManager: StoreKitManager()) }
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