import Foundation

enum MoonPhase: String, Sendable, CaseIterable {
    case newMoon
    case waxingCrescent
    case firstQuarter
    case waxingGibbous
    case fullMoon
    case waningGibbous
    case lastQuarter
    case waningCrescent

    var label: String {
        switch self {
        case .newMoon: "New Moon"
        case .waxingCrescent: "Waxing Crescent"
        case .firstQuarter: "First Quarter"
        case .waxingGibbous: "Waxing Gibbous"
        case .fullMoon: "Full Moon"
        case .waningGibbous: "Waning Gibbous"
        case .lastQuarter: "Last Quarter"
        case .waningCrescent: "Waning Crescent"
        }
    }
}

struct SolarTimes: Sendable, Equatable {
    let sunrise: Date
    let sunset: Date
}

struct TideEnergyWindow: Sendable, Equatable, Identifiable {
    let id: UUID
    let start: Date
    let end: Date
    let label: String
    let score: Double

    init(id: UUID = UUID(), start: Date, end: Date, label: String, score: Double) {
        self.id = id
        self.start = start
        self.end = end
        self.label = label
        self.score = score
    }
}

enum LunarSolarEngine {
    private static let synodicMonth: TimeInterval = 29.530588853 * 86_400

    static func moonPhase(for date: Date, referenceNewMoon: Date = referenceNewMoonDate) -> MoonPhase {
        let elapsed = date.timeIntervalSince(referenceNewMoon).truncatingRemainder(dividingBy: synodicMonth)
        let normalized = elapsed < 0 ? elapsed + synodicMonth : elapsed
        let fraction = normalized / synodicMonth

        switch fraction {
        case 0..<0.03, 0.97...1.0: return .newMoon
        case 0.03..<0.22: return .waxingCrescent
        case 0.22..<0.28: return .firstQuarter
        case 0.28..<0.47: return .waxingGibbous
        case 0.47..<0.53: return .fullMoon
        case 0.53..<0.72: return .waningGibbous
        case 0.72..<0.78: return .lastQuarter
        default: return .waningCrescent
        }
    }

    static func solarTimes(
        for date: Date,
        latitude: Double,
        longitude: Double,
        calendar: Calendar = .current
    ) -> SolarTimes {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let declination = 23.45 * sin(2 * .pi * (284 + Double(dayOfYear)) / 365)
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180
        let hourAngle = acos(max(-1, min(1, -tan(latRad) * tan(decRad))))
        let solarNoonOffsetHours = longitude / 15.0
        let daylightHours = 2 * hourAngle * 12 / .pi
        let startOfDay = calendar.startOfDay(for: date)
        let solarNoon = startOfDay.addingTimeInterval((12 - solarNoonOffsetHours) * 3600)
        let sunrise = solarNoon.addingTimeInterval(-daylightHours / 2 * 3600)
        let sunset = solarNoon.addingTimeInterval(daylightHours / 2 * 3600)
        return SolarTimes(sunrise: sunrise, sunset: sunset)
    }

    static func tideEnergyWindows(
        extremes: [TideExtreme],
        solar: SolarTimes,
        calendar: Calendar = .current
    ) -> [TideEnergyWindow] {
        var windows: [TideEnergyWindow] = []

        for extreme in extremes.sorted(by: { $0.time < $1.time }) {
            let goldenHourProximity = min(
                abs(extreme.time.timeIntervalSince(solar.sunrise)),
                abs(extreme.time.timeIntervalSince(solar.sunset))
            )
            let score = max(0, 1 - goldenHourProximity / (3 * 3600))
            guard score > 0.3 else { continue }

            let label = extreme.kind == .high ? "High tide energy" : "Low tide calm"
            let start = extreme.time.addingTimeInterval(-1800)
            let end = extreme.time.addingTimeInterval(1800)
            windows.append(TideEnergyWindow(start: start, end: end, label: label, score: score))
        }

        return windows.sorted { $0.score > $1.score }
    }

    private static var referenceNewMoonDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2000, month: 1, day: 6, hour: 18, minute: 14))!
    }
}