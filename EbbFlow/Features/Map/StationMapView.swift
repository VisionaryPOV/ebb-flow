import MapKit
import SwiftUI

struct StationMapView: View {
    @Bindable var appModel: AppModel
    @State private var region: MKCoordinateRegion
    @State private var spots: [FavoriteSpot] = []
    @Namespace private var mapControls

    init(appModel: AppModel) {
        self.appModel = appModel
        _region = State(initialValue: MKCoordinateRegion(
            center: appModel.selectedStation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: .constant(.region(region))) {
                ForEach(spots, id: \.stationID) { spot in
                    Annotation(spot.name, coordinate: spot.station.coordinate) {
                        Button {
                            Task { await appModel.load(station: spot.station) }
                        } label: {
                            Image(systemName: spot.stationID == appModel.selectedStation.id ? "water.waves" : "mappin")
                                .padding(8)
                                .background(
                                    spot.stationID == appModel.selectedStation.id
                                        ? Color.cyan.opacity(0.85)
                                        : Color.orange.opacity(0.85),
                                    in: Circle()
                                )
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            GlassEffectContainer {
                VStack(spacing: 1) {
                    Button { zoom(by: 0.5) } label: {
                        Image(systemName: "plus")
                            .frame(width: 36, height: 36)
                    }
                    .glassEffectUnion(id: "zoom", namespace: mapControls)

                    Divider().frame(width: 24)

                    Button { zoom(by: 2) } label: {
                        Image(systemName: "minus")
                            .frame(width: 36, height: 36)
                    }
                    .glassEffectUnion(id: "zoom", namespace: mapControls)
                }
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Map")
        .task { reload() }
        .onChange(of: appModel.selectedStation.id) { _, _ in
            centerOnSelection()
        }
        .onChange(of: appModel.spotsRevision) { _, _ in
            reload()
        }
    }

    private func reload() {
        spots = (try? appModel.spotsStore.allSpots()) ?? []
        if spots.isEmpty {
            spots = [FavoriteSpot(station: appModel.selectedStation)]
        }
        fitRegion()
    }

    private func centerOnSelection() {
        region.center = appModel.selectedStation.coordinate
    }

    private func fitRegion() {
        let coordinates = spots.map(\.station.coordinate)
        guard let first = coordinates.first else { return }
        if coordinates.count == 1 {
            region.center = first
            return
        }

        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (latitudes.min()! + latitudes.max()!) / 2,
            longitude: (longitudes.min()! + longitudes.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((latitudes.max()! - latitudes.min()!) * 1.4, 0.08),
            longitudeDelta: max((longitudes.max()! - longitudes.min()!) * 1.4, 0.08)
        )
        region = MKCoordinateRegion(center: center, span: span)
    }

    private func zoom(by factor: Double) {
        region.span.latitudeDelta *= factor
        region.span.longitudeDelta *= factor
    }
}