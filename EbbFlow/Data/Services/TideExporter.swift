import Foundation

enum TideExporter {
    private static let csvDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    static func csv(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases)
    ) -> String {
        let visible = TideTableBuilder.visibleColumns(columns)
        var lines: [String] = []
        lines.append("# Station: \(stationName)")
        lines.append(visible.map(\.header).joined(separator: ","))

        for row in rows {
            var fields: [String] = []
            for column in visible {
                switch column {
                case .time:
                    fields.append(csvDateFormatter.string(from: row.time))
                case .height:
                    fields.append(String(format: "%.2f", row.height))
                case .kind:
                    fields.append(row.kind?.label ?? "")
                }
            }
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func pdfData(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases)
    ) -> Data {
        let visible = TideTableBuilder.visibleColumns(columns)
        var text = "Ebb & Flow — \(stationName)\n\n"
        text += visible.map(\.header).joined(separator: " | ")
        text += "\n"
        text += String(repeating: "-", count: 40)
        text += "\n"

        for row in rows {
            var fields: [String] = []
            for column in visible {
                switch column {
                case .time:
                    fields.append(csvDateFormatter.string(from: row.time))
                case .height:
                    fields.append(String(format: "%.1f ft", row.height))
                case .kind:
                    fields.append(row.kind?.label ?? "")
                }
            }
            text += fields.joined(separator: " | ")
            text += "\n"
        }

        var data = Data()
        data.append("%PDF-1.4\n".data(using: .utf8)!)
        data.append("1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n".data(using: .utf8)!)
        data.append("2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n".data(using: .utf8)!)
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
        let stream = "BT /F1 10 Tf 50 750 Td (\(escaped)) Tj ET"
        data.append("3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj\n".data(using: .utf8)!)
        data.append("4 0 obj << /Length \(stream.utf8.count) >> stream\n\(stream)\nendstream endobj\n".data(using: .utf8)!)
        data.append("5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n".data(using: .utf8)!)
        data.append("xref\n0 6\n0000000000 65535 f \ntrailer << /Size 6 /Root 1 0 R >>\nstartxref\n0\n%%EOF\n".data(using: .utf8)!)
        return data
    }

    static func writeCSVFile(csv: String, stationID: String) throws -> URL {
        let sanitizedID = stationID.replacingOccurrences(of: ",", with: "_")
        let filename = "ebb-flow-\(sanitizedID)-tides.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}