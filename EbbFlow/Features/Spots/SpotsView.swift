import PhotosUI
import SwiftUI

struct SpotsView: View {
    @Bindable var appModel: AppModel
    @State private var spots: [FavoriteSpot] = []
    @State private var editingStationID: String?
    @State private var showingStationSearch = false

    var body: some View {
        List {
            if spots.isEmpty {
                ContentUnavailableView(
                    "No spots yet",
                    systemImage: "mappin.and.ellipse",
                    description: Text("Find a tide station or save one from Today.")
                )
            } else {
                ForEach(spots, id: \.stationID) { spot in
                    Button {
                        Task { await appModel.load(station: spot.station) }
                    } label: {
                        SpotRow(spot: spot)
                    }
                    .swipeActions {
                        Button("Edit") { editingStationID = spot.stationID }
                    }
                }
                .onDelete(perform: deleteSpots)
            }
        }
        .navigationTitle("My Spots")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingStationSearch = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add spot")
            }
        }
        .sheet(isPresented: $showingStationSearch) {
            StationSearchView(appModel: appModel)
        }
        .task { reload() }
        .refreshable { reload() }
        .sheet(isPresented: Binding(
            get: { editingStationID != nil },
            set: { if !$0 { editingStationID = nil } }
        )) {
            if let stationID = editingStationID,
               let spot = spots.first(where: { $0.stationID == stationID }) {
                SpotEditorSheet(spot: spot, appModel: appModel) {
                    editingStationID = nil
                    reload()
                }
            }
        }
    }

    private func reload() {
        spots = (try? appModel.spotsStore.allSpots()) ?? []
    }

    private func deleteSpots(at offsets: IndexSet) {
        for index in offsets {
            let spot = spots[index]
            try? appModel.spotsStore.removeSpot(stationID: spot.stationID)
        }
        appModel.notifySpotsChanged()
        reload()
    }
}

private struct SpotRow: View {
    let spot: FavoriteSpot

    var body: some View {
        HStack(spacing: 12) {
            if !spot.photoPath.isEmpty, let image = PhotoStorage.load(path: spot.photoPath) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 44, height: 44)
                    .background(.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name).font(.headline)
                if spot.personalOffsetFeet != 0 {
                    Text(String(format: "Offset: %+.1f ft", spot.personalOffsetFeet))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !spot.notes.isEmpty {
                    Text(spot.notes).font(.subheadline).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SpotEditorSheet: View {
    let spot: FavoriteSpot
    @Bindable var appModel: AppModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var notes: String
    @State private var offset: Double
    @State private var photoItem: PhotosPickerItem?
    @State private var photoPath: String

    init(spot: FavoriteSpot, appModel: AppModel, onSave: @escaping () -> Void) {
        self.spot = spot
        self.appModel = appModel
        self.onSave = onSave
        _name = State(initialValue: spot.name)
        _notes = State(initialValue: spot.notes)
        _offset = State(initialValue: spot.personalOffsetFeet)
        _photoPath = State(initialValue: spot.photoPath)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Name", text: $name)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
                Section("Personal Offset") {
                    Stepper(String(format: "%+.1f ft", offset), value: $offset, in: -5...5, step: 0.1)
                }
                Section("Photo") {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo")
                    }
                }
            }
            .navigationTitle(spot.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let path = await PhotoStorage.save(photoItem: item, prefix: spot.stationID) {
                        photoPath = path
                    }
                }
            }
        }
    }

    private func save() {
        try? appModel.spotsStore.updateSpot(
            stationID: spot.stationID,
            name: name,
            notes: notes,
            photoPath: photoPath,
            personalOffsetFeet: offset
        )
        appModel.notifySpotsChanged()
        onSave()
        dismiss()
    }
}

