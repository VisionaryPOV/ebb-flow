import CoreLocation
import SwiftUI

struct StationSearchView: View {
    @Bindable var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var stations: [NOAAStationRecord] = []
    @State private var nearestResults: [(record: NOAAStationRecord, distanceMeters: Double)] = []
    @State private var browseStates: [(state: String, count: Int)] = []
    @State private var selectedBrowseState: String?
    @State private var isLoading = true
    @State private var isLocating = false
    @State private var loadError: String?
    @State private var favoriteOnSelect = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        Task { await locateNearest() }
                    } label: {
                        Label {
                            if isLocating {
                                Text("Finding nearby stations…")
                            } else {
                                Text("Near Me")
                            }
                        } icon: {
                            Image(systemName: "location.fill")
                        }
                    }
                    .disabled(isLocating || isLoading)
                }

                if !nearestResults.isEmpty {
                    Section("Nearest") {
                        ForEach(nearestResults, id: \.record.id) { item in
                            stationButton(item.record, distanceMeters: item.distanceMeters)
                        }
                    }
                }

                if let selectedBrowseState {
                    Section(selectedBrowseState) {
                        ForEach(NOAAStationDiscovery.stations(inState: selectedBrowseState, from: stations), id: \.id) { record in
                            stationButton(record)
                        }
                    }
                } else if searchText.isEmpty {
                    Section("Browse") {
                        ForEach(browseStates, id: \.state) { entry in
                            Button(entry.state) {
                                selectedBrowseState = entry.state
                            }
                            .badge(entry.count)
                        }
                    }
                }

                if !searchText.isEmpty {
                    Section("Results") {
                        let results = NOAAStationDiscovery.filter(stations: stations, query: searchText)
                        if results.isEmpty {
                            Text("No stations match \"\(searchText)\".")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(results, id: \.id) { record in
                                stationButton(record)
                            }
                        }
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Loading tide stations…")
                }
            }
            .navigationTitle("Find Station")
            .searchable(text: $searchText, prompt: "City, beach, or station")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedBrowseState != nil {
                        Button("Browse") { selectedBrowseState = nil }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $favoriteOnSelect) {
                        Image(systemName: favoriteOnSelect ? "star.fill" : "star")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Save as favorite when selecting")
                }
            }
            .task { await loadCatalog() }
            .alert("Station Search", isPresented: Binding(
                get: { loadError != nil },
                set: { if !$0 { loadError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(loadError ?? "")
            }
        }
    }

    @ViewBuilder
    private func stationButton(_ record: NOAAStationRecord, distanceMeters: Double? = nil) -> some View {
        Button {
            Task {
                await appModel.selectStation(record: record, favorite: favoriteOnSelect)
                dismiss()
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.name)
                        .font(.headline)
                    if !record.isReferenceStation {
                        Text("Sub")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.15), in: Capsule())
                    }
                }
                HStack(spacing: 8) {
                    if !record.state.isEmpty {
                        Text(record.state)
                    }
                    Text("ID \(record.id)")
                        .foregroundStyle(.secondary)
                    if let distanceMeters {
                        Text(distanceLabel(distanceMeters))
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.caption)
            }
        }
    }

    private func distanceLabel(_ meters: Double) -> String {
        let miles = meters / 1_609.34
        if miles < 10 {
            return String(format: "%.1f mi", miles)
        }
        return String(format: "%.0f mi", miles)
    }

    private func loadCatalog() async {
        isLoading = true
        defer { isLoading = false }
        do {
            stations = try await appModel.stationMetadata.allStations()
            browseStates = NOAAStationDiscovery.states(from: stations)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func locateNearest() async {
        isLocating = true
        defer { isLocating = false }
        do {
            if stations.isEmpty {
                stations = try await appModel.stationMetadata.allStations()
            }
            let coordinate = try await appModel.locationService.currentCoordinate()
            nearestResults = NOAAStationDiscovery.nearest(stations: stations, to: coordinate, limit: 3)
            if nearestResults.isEmpty {
                loadError = "No tide stations found near your location."
            }
        } catch {
            loadError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}