import PhotosUI
import SwiftUI

struct JournalView: View {
    @Bindable var appModel: AppModel
    @State private var entries: [JournalEntry] = []
    @State private var notes = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var searchText = ""

    var body: some View {
        List {
            Section("Log the moment") {
                TextField("What did the ocean give you today?", text: $notes, axis: .vertical)
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Attach photo", systemImage: "photo")
                }
                Button("Save entry") { saveEntry() }
                    .disabled(notes.isEmpty && photoItem == nil)
            }

            Section("Memories") {
                if filteredEntries.isEmpty {
                    Text("No journal entries yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredEntries, id: \.id) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.stationName).font(.headline)
                            Text(formatted(entry.recordedAt)).font(.caption).foregroundStyle(.secondary)
                            Text(String(format: "%.1f ft", entry.tideHeightFeet)).monospacedDigit()
                            if !entry.notes.isEmpty { Text(entry.notes) }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Journal")
        .task { reload() }
    }

    private var filteredEntries: [JournalEntry] {
        (try? appModel.journalStore.search(query: searchText)) ?? entries
    }

    private func reload() {
        entries = (try? appModel.journalStore.allEntries()) ?? []
    }

    private func saveEntry() {
        Task {
            var photoPath = ""
            if let path = await PhotoStorage.save(photoItem: photoItem, prefix: "journal") {
                photoPath = path
            }
            appModel.logJournalEntry(notes: notes, photoPath: photoPath)
            notes = ""
            photoItem = nil
            reload()
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            let entry = filteredEntries[index]
            try? appModel.journalStore.removeEntry(id: entry.id)
        }
        reload()
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}