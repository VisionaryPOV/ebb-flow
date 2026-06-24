import Foundation

struct TideExtreme: Identifiable, Codable, Sendable, Hashable {
    let id: UUID
    let time: Date
    let height: Double
    let kind: TideKind

    init(id: UUID = UUID(), time: Date, height: Double, kind: TideKind) {
        self.id = id
        self.time = time
        self.height = height
        self.kind = kind
    }
}