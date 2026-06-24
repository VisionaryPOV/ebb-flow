import SwiftUI

enum AppFeature: String, CaseIterable, Hashable, Identifiable {
    case today
    case spots
    case map
    case journal
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .spots: "Spots"
        case .map: "Map"
        case .journal: "Journal"
        case .more: "More"
        }
    }

    var icon: String {
        switch self {
        case .today: "water.waves"
        case .spots: "mappin.and.ellipse"
        case .map: "map"
        case .journal: "book.closed"
        case .more: "ellipsis.circle"
        }
    }
}

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
    @State private var selectedFeature: AppFeature = .today
    @State private var selectedStationID: String?

    private var sidebarSpots: [FavoriteSpot] {
        spots.filter { $0.stationID != appModel.selectedStation.id }
    }

    var body: some View {
        NavigationSplitView {
            List {
                Section("Browse") {
                    ForEach(AppFeature.allCases) { feature in
                        Button {
                            selectedFeature = feature
                        } label: {
                            Label(feature.title, systemImage: feature.icon)
                        }
                        .listRowBackground(
                            selectedFeature == feature ? Color.accentColor.opacity(0.12) : Color.clear
                        )
                    }
                }
                Section("Current") {
                    Button {
                        selectedFeature = .today
                        selectedStationID = appModel.selectedStation.id
                    } label: {
                        Text(appModel.selectedStation.name)
                    }
                    .listRowBackground(
                        selectedFeature == .today && selectedStationID == appModel.selectedStation.id
                            ? Color.accentColor.opacity(0.12)
                            : Color.clear
                    )
                }
                if !sidebarSpots.isEmpty {
                    Section("My Spots") {
                        ForEach(sidebarSpots, id: \.stationID) { spot in
                            Button {
                                selectedFeature = .today
                                selectedStationID = spot.stationID
                                Task { await appModel.load(station: spot.station) }
                            } label: {
                                Text(spot.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ebb & Flow")
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
        } detail: {
            NavigationStack {
                featureView(selectedFeature)
            }
        }
    }

    @ViewBuilder
    private func featureView(_ feature: AppFeature) -> some View {
        switch feature {
        case .today:
            TodayView(appModel: appModel)
        case .spots:
            SpotsView(appModel: appModel)
        case .map:
            StationMapView(station: appModel.selectedStation)
        case .journal:
            JournalView(appModel: appModel)
        case .more:
            MoreView(storeManager: appModel.storeManager)
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
                NavigationStack { MoreView(storeManager: appModel.storeManager) }
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