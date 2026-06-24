import Foundation

enum TideTableColumn: String, CaseIterable, Sendable {
    case time
    case height
    case kind

    var header: String {
        switch self {
        case .time: "Time"
        case .height: "Height (ft)"
        case .kind: "Type"
        }
    }
}

struct TideTableRow: Sendable, Equatable, Identifiable {
    let id: UUID
    let time: Date
    let height: Double
    let kind: TideKind?

    init(id: UUID = UUID(), time: Date, height: Double, kind: TideKind?) {
        self.id = id
        self.time = time
        self.height = height
        self.kind = kind
    }
}

enum TideTableBuilder {
    static func rows(
        from extremes: [TideExtreme],
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases)
    ) -> [TideTableRow] {
        guard !effectiveColumns(columns).isEmpty else { return [] }
        return extremes.sorted { $0.time < $1.time }.map {
            TideTableRow(time: $0.time, height: $0.height, kind: $0.kind)
        }
    }

    static func effectiveColumns(_ selected: Set<TideTableColumn>) -> Set<TideTableColumn> {
        selected.isEmpty ? Set(TideTableColumn.allCases) : selected
    }

    static func visibleColumns(_ selected: Set<TideTableColumn>) -> [TideTableColumn] {
        TideTableColumn.allCases.filter { effectiveColumns(selected).contains($0) }
    }
}