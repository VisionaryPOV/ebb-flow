import Foundation
import SwiftData
import Testing
@testable import EbbFlow

struct Phase2Tests {
    private static let pacific = TimeZone(identifier: "America/Los_Angeles")!

    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = pacific
        return cal
    }

    @Test func dateRangeWeekFiltersHeights() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        let anchor = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let range = TideDateRangeCalculator.weekRange(containing: anchor, calendar: Self.calendar)
        let filtered = TideDateRangeCalculator.filterHeights(heights, in: range)

        #expect(!filtered.isEmpty)
        #expect(filtered.first!.time >= range.lowerBound)
        #expect(filtered.last!.time <= range.upperBound)
    }

    @Test func dateRangeMonthSpans30Days() throws {
        let anchor = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24))!
        let range = TideDateRangeCalculator.monthRange(containing: anchor, calendar: Self.calendar)
        let days = Self.calendar.dateComponents([.day], from: range.lowerBound, to: range.upperBound).day ?? 0
        #expect(days == 30)
    }

    @Test func chartPointsNormalizeWithinRange() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        let anchor = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let range = TideDateRangeCalculator.weekRange(containing: anchor, calendar: Self.calendar)
        let points = TideCurvePointGenerator.chartPoints(from: heights, in: range)

        #expect(!points.isEmpty)
        #expect(points.map(\.normalizedY).min() == 0)
        #expect(points.map(\.normalizedY).max() == 1)
    }

    @Test func weeklyWaveLevelsMatchPointCount() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        let anchor = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let range = TideDateRangeCalculator.weekRange(containing: anchor, calendar: Self.calendar)
        let levels = WaveFillCalculator.weeklyWaveLevels(for: heights, in: range)
        let filtered = TideDateRangeCalculator.filterHeights(heights, in: range)
        #expect(levels.count == filtered.count)
        #expect(levels.allSatisfy { (0...1).contains($0) })
    }

    @Test func monthlyWaveLevelsSpanMonthRange() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_heights")
        let heights = try TideDataTransformer.parseHeights(from: data, timeZone: Self.pacific)
        let anchor = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let range = TideDateRangeCalculator.monthRange(containing: anchor, calendar: Self.calendar)
        let levels = WaveFillCalculator.weeklyWaveLevels(for: heights, in: range)
        let filtered = TideDateRangeCalculator.filterHeights(heights, in: range)

        #expect(!levels.isEmpty)
        #expect(levels.count == filtered.count)
        #expect(filtered.first!.time >= range.lowerBound)
        #expect(filtered.last!.time <= range.upperBound)
    }

    @Test @MainActor func iPadSidebarSpotsRevisionIncrementsOnFavoriteToggle() throws {
        let schema = Schema([FavoriteSpot.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let model = AppModel(modelContext: context)

        #expect(model.spotsRevision == 0)
        model.toggleFavorite()
        #expect(model.spotsRevision == 1)
        model.toggleFavorite()
        #expect(model.spotsRevision == 2)
    }

    @Test func waveLevelsVectorSupportsVectorArithmetic() {
        let a = WaveLevelsVector(values: [0.0, 0.5, 1.0])
        let b = WaveLevelsVector(values: [1.0, 0.0, 0.5])

        #expect((a + b).values == [1.0, 0.5, 1.5])
        #expect((b - a).values == [1.0, -0.5, -0.5])

        var scaled = a
        scaled.scale(by: 2)
        #expect(scaled.values == [0.0, 1.0, 2.0])
        #expect(a.magnitudeSquared == 1.25)
    }

    @Test func csvExportContainsStationAndRows() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let csv = TideExporter.csv(rows: rows, stationName: "Marina del Rey")

        #expect(csv.contains("Marina del Rey"))
        #expect(csv.contains("High"))
        #expect(csv.contains("0.82"))
    }

    @Test func csvExportWritesTemporaryFile() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let csv = TideExporter.csv(rows: rows, stationName: "Marina del Rey")
        let url = try TideExporter.writeCSVFile(csv: csv, stationID: "9410840")

        #expect(FileManager.default.fileExists(atPath: url.path))
        let written = try String(contentsOf: url, encoding: .utf8)
        #expect(written == csv)
        #expect(url.lastPathComponent.contains("9410840"))
    }

    @Test func pdfExportProducesPDFHeader() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let pdf = TideExporter.pdfData(rows: rows, stationName: "Marina del Rey")
        let header = String(data: pdf.prefix(8), encoding: .utf8) ?? ""
        #expect(header.hasPrefix("%PDF"))
    }

    @Test func pdfExportEmbedsAllRowTimestamps() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let pdf = TideExporter.pdfData(rows: rows, stationName: "Marina del Rey")
        let pdfText = String(data: pdf, encoding: .utf8) ?? ""

        for row in rows {
            let timestamp = TideExporter.pdfTextLines(rows: [row], stationName: "Marina del Rey")[4]
            #expect(pdfText.contains(timestamp))
        }
        #expect(pdfText.contains("Marina del Rey"))
    }

    @Test func pdfTextPagesSplitsLongTables() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let pages = TideExporter.pdfTextPages(
            rows: rows,
            stationName: "Marina del Rey",
            maxLinesPerPage: 3
        )

        #expect(pages.count > 1)
        let combined = pages.joined(separator: "\n")
        for row in rows {
            let timestamp = TideExporter.pdfTextLines(rows: [row], stationName: "Marina del Rey")[4]
            #expect(combined.contains(timestamp))
        }
    }

    @Test func pdfExportWritesTemporaryFile() throws {
        let data = try FixtureLoader.data(named: "marina_del_rey_hilo")
        let extremes = try TideDataTransformer.parseExtremes(from: data, timeZone: Self.pacific)
        let rows = TideTableBuilder.rows(from: extremes)
        let url = try TideExporter.writePDFFile(
            rows: rows,
            stationName: "Marina del Rey",
            stationID: "9410840"
        )

        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(url.pathExtension == "pdf")
        let written = try Data(contentsOf: url)
        let header = String(data: written.prefix(8), encoding: .utf8) ?? ""
        #expect(header.hasPrefix("%PDF"))
    }
}