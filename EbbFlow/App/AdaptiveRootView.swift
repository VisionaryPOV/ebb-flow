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
    @State private var selectedStationID: String?

    private var sidebarSpots: [FavoriteSpot] {
        spots.filter { $0.stationID != appModel.selectedStation.id }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedStationID) {
                Section("Current") {
                    NavigationLink(value: appModel.selectedStation.id) {
                        Text(appModel.selectedStation.name)
                    }
                }
                if !sidebarSpots.isEmpty {
                    Section("My Spots") {
                        ForEach(sidebarSpots, id: \.stationID) { spot in
                            NavigationLink(value: spot.stationID) { Text(spot.name) }
                        }
                    }
                }
            }
            .navigationTitle("Stations")
            .refreshable { reloadSpots() }
            .task {
                reloadSpots()
                selectedStationID = appModel.selectedStation.id
            }
            .onChange(of: appModel.selectedStation.id) { _, newID in
                selectedStationID = newID
            }
            .onChange(of: appModel.spotsRevision) { _, _ in
                reloadSpots()
            }
            .onChange(of: selectedStationID) { _, newID in
                guard let newID, newID != appModel.selectedStation.id else { return }
                if let spot = spots.first(where: { $0.stationID == newID }) {
                    Task { await appModel.load(station: spot.station) }
                } else if let station = TideStationCatalog.resolve(id: newID) {
                    Task { await appModel.load(station: station) }
                }
            }
        } detail: {
            NavigationStack {
                TodayView(appModel: appModel)
            }
        }
    }

    private func reloadSpots() {
        spots = (try? appModel.spotsStore.allSpots()) ?? []
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