import Foundation

enum TideExporter {
    static func csv(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases),
        timeZone: TimeZone = TideDataTransformer.noaaLocalTimeZone
    ) -> String {
        let formatter = TideDataTransformer.makePredictionDateFormatter(timeZone: timeZone)
        let visible = TideTableBuilder.visibleColumns(columns)
        var lines: [String] = []
        lines.append("# Station: \(stationName)")
        lines.append(visible.map(\.header).joined(separator: ","))

        for row in rows {
            var fields: [String] = []
            for column in visible {
                switch column {
                case .time:
                    fields.append(formatter.string(from: row.time))
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

    static func pdfTextLines(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases),
        timeZone: TimeZone = TideDataTransformer.noaaLocalTimeZone
    ) -> [String] {
        let formatter = TideDataTransformer.makePredictionDateFormatter(timeZone: timeZone)
        let visible = TideTableBuilder.visibleColumns(columns)
        var lines: [String] = []
        lines.append("Ebb & Flow — \(stationName)")
        lines.append("")
        lines.append(visible.map(\.header).joined(separator: " | "))
        lines.append(String(repeating: "-", count: 40))

        for row in rows {
            var fields: [String] = []
            for column in visible {
                switch column {
                case .time:
                    fields.append(formatter.string(from: row.time))
                case .height:
                    fields.append(String(format: "%.1f ft", row.height))
                case .kind:
                    fields.append(row.kind?.label ?? "")
                }
            }
            lines.append(fields.joined(separator: " | "))
        }
        return lines
    }

    static func pdfTextPages(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases),
        maxLinesPerPage: Int = 40,
        timeZone: TimeZone = TideDataTransformer.noaaLocalTimeZone
    ) -> [String] {
        let lines = pdfTextLines(rows: rows, stationName: stationName, columns: columns, timeZone: timeZone)
        guard !lines.isEmpty else { return [""] }

        var pages: [String] = []
        var index = 0
        while index < lines.count {
            let end = min(index + maxLinesPerPage, lines.count)
            pages.append(lines[index..<end].joined(separator: "\n"))
            index = end
        }
        return pages
    }

    static func pdfData(
        rows: [TideTableRow],
        stationName: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases),
        maxLinesPerPage: Int = 40,
        timeZone: TimeZone = TideDataTransformer.noaaLocalTimeZone
    ) -> Data {
        let pages = pdfTextPages(
            rows: rows,
            stationName: stationName,
            columns: columns,
            maxLinesPerPage: maxLinesPerPage,
            timeZone: timeZone
        )
        return buildPDF(from: pages)
    }

    static func writeCSVFile(
        csv: String,
        stationID: String
    ) throws -> URL {
        let sanitizedID = stationID.replacingOccurrences(of: ",", with: "_")
        let filename = "ebb-flow-\(sanitizedID)-tides.csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func writePDFFile(
        rows: [TideTableRow],
        stationName: String,
        stationID: String,
        columns: Set<TideTableColumn> = Set(TideTableColumn.allCases),
        maxLinesPerPage: Int = 40,
        timeZone: TimeZone = TideDataTransformer.noaaLocalTimeZone
    ) throws -> URL {
        let pdf = pdfData(
            rows: rows,
            stationName: stationName,
            columns: columns,
            maxLinesPerPage: maxLinesPerPage,
            timeZone: timeZone
        )
        let sanitizedID = stationID.replacingOccurrences(of: ",", with: "_")
        let filename = "ebb-flow-\(sanitizedID)-tides.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try pdf.write(to: url)
        return url
    }

    private static func buildPDF(from pages: [String]) -> Data {
        var objects: [String] = []
        objects.append("1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n")

        let pageObjectIDs = (0..<pages.count).map { 3 + ($0 * 2) }
        let kids = pageObjectIDs.map { "\($0) 0 R" }.joined(separator: " ")
        objects.append("2 0 obj << /Type /Pages /Kids [\(kids)] /Count \(pages.count) >> endobj\n")

        var contentObjectID = 4
        for (index, pageText) in pages.enumerated() {
            let pageObjectID = pageObjectIDs[index]
            let stream = pdfContentStream(for: pageText)
            objects.append("\(pageObjectID) 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents \(contentObjectID) 0 R /Resources << /Font << /F1 \(3 + pages.count * 2) 0 R >> >> >> endobj\n")
            objects.append("\(contentObjectID) 0 obj << /Length \(stream.utf8.count) >> stream\n\(stream)\nendstream endobj\n")
            contentObjectID += 2
        }

        let fontObjectID = 3 + pages.count * 2
        objects.append("\(fontObjectID) 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj\n")

        var data = Data()
        data.append("%PDF-1.4\n".data(using: .utf8)!)

        var offsets: [Int] = [0]
        for object in objects {
            offsets.append(data.count)
            data.append(object.data(using: .utf8)!)
        }

        let xrefOffset = data.count
        let objectCount = objects.count + 1
        var xref = "xref\n0 \(objectCount)\n0000000000 65535 f \n"
        for offset in offsets.dropFirst() {
            xref += String(format: "%010d 00000 n \n", offset)
        }
        data.append(xref.data(using: .utf8)!)
        data.append("trailer << /Size \(objectCount) /Root 1 0 R >>\nstartxref\n\(xrefOffset)\n%%EOF\n".data(using: .utf8)!)
        return data
    }

    private static func pdfContentStream(for pageText: String) -> String {
        let lines = pageText.split(separator: "\n", omittingEmptySubsequences: false)
        var commands = ["BT", "/F1 10 Tf", "50 750 Td"]
        for (index, line) in lines.enumerated() {
            if index > 0 {
                commands.append("0 -12 Td")
            }
            commands.append("(\(pdfEscaped(String(line)))) Tj")
        }
        commands.append("ET")
        return commands.joined(separator: "\n")
    }

    private static func pdfEscaped(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
    }
}