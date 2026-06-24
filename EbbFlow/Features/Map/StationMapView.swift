import MapKit
import SwiftUI

struct StationMapView: View {
    let station: TideStation
    @State private var region: MKCoordinateRegion
    @Namespace private var mapControls

    init(station: TideStation) {
        self.station = station
        _region = State(initialValue: MKCoordinateRegion(
            center: station.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(position: .constant(.region(region))) {
                Annotation(station.name, coordinate: station.coordinate) {
                    Image(systemName: "water.waves")
                        .padding(8)
                        .background(.cyan.opacity(0.85), in: Circle())
                        .foregroundStyle(.white)
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
    }

    private func zoom(by factor: Double) {
        region.span.latitudeDelta *= factor
        region.span.longitudeDelta *= factor
    }
}