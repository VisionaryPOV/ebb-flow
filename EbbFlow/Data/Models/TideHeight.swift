import Foundation

struct TideHeight: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let time: Date
    let height: Double

    init(id: UUID = UUID(), time: Date, height: Double) {
        self.id = id
        self.time = time
        self.height = height
    }
}