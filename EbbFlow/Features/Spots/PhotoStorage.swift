import PhotosUI
import SwiftUI
import UIKit

enum PhotoStorage {
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func save(photoItem: PhotosPickerItem?, prefix: String) async -> String? {
        guard let photoItem,
              let data = try? await photoItem.loadTransferable(type: Data.self) else {
            return nil
        }
        let filename = "\(prefix)-\(UUID().uuidString).jpg"
        let url = documentsDirectory().appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    static func load(path: String) -> Image? {
        let url = documentsDirectory().appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }

    static func delete(path: String) {
        guard !path.isEmpty else { return }
        let url = documentsDirectory().appendingPathComponent(path)
        try? FileManager.default.removeItem(at: url)
    }
}