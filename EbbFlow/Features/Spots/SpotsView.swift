import SwiftUI

struct SpotsView: View {
    @Bindable var appModel: AppModel
    @State private var spots: [FavoriteSpot] = []

    var body: some View {
        List {
            if spots.isEmpty {
                ContentUnavailableView(
                    "No spots yet",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Save a station from Today to build your coast.")
                )
            } else {
                ForEach(spots, id: \.stationID) { spot in
                    Button {
                        Task { await appModel.load(station: spot.station) }
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(spot.name)
                                .font(.headline)
                            Text(spot.stationID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !spot.notes.isEmpty {
                                Text(spot.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSpots)
            }
        }
        .navigationTitle("My Spots")
        .task { reload() }
        .refreshable { reload() }
    }

    private func reload() {
        spots = (try? appModel.spotsStore.allSpots()) ?? []
    }

    private func deleteSpots(at offsets: IndexSet) {
        for index in offsets {
            let spot = spots[index]
            try? appModel.spotsStore.removeSpot(stationID: spot.stationID)
        }
        reload()
    }
}