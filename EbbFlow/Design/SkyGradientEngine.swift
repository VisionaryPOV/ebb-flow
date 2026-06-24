import Foundation
import SwiftUI

struct GradientStopValue: Sendable, Equatable {
    let location: Double
    let red: Double
    let green: Double
    let blue: Double

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
}

enum SkyPhase: String, Sendable, CaseIterable {
    case preDawn
    case dawn
    case morning
    case midday
    case afternoon
    case goldenHour
    case dusk
    case night
}

enum SkyGradientEngine {
    static func phase(for date: Date, calendar: Calendar = .current) -> SkyPhase {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let fractionalHour = Double(hour) + Double(minute) / 60.0

        switch fractionalHour {
        case 0..<5: return .preDawn
        case 5..<7: return .dawn
        case 7..<11: return .morning
        case 11..<14: return .midday
        case 14..<17: return .afternoon
        case 17..<19: return .goldenHour
        case 19..<21: return .dusk
        default: return .night
        }
    }

    static func stops(for phase: SkyPhase) -> [GradientStopValue] {
        switch phase {
        case .preDawn:
            return [
                GradientStopValue(location: 0.0, red: 0.05, green: 0.08, blue: 0.18),
                GradientStopValue(location: 1.0, red: 0.10, green: 0.12, blue: 0.28)
            ]
        case .dawn:
            return [
                GradientStopValue(location: 0.0, red: 0.20, green: 0.25, blue: 0.45),
                GradientStopValue(location: 1.0, red: 0.85, green: 0.55, blue: 0.45)
            ]
        case .morning:
            return [
                GradientStopValue(location: 0.0, red: 0.45, green: 0.70, blue: 0.85),
                GradientStopValue(location: 1.0, red: 0.65, green: 0.82, blue: 0.92)
            ]
        case .midday:
            return [
                GradientStopValue(location: 0.0, red: 0.10, green: 0.35, blue: 0.55),
                GradientStopValue(location: 1.0, red: 0.25, green: 0.55, blue: 0.72)
            ]
        case .afternoon:
            return [
                GradientStopValue(location: 0.0, red: 0.08, green: 0.30, blue: 0.50),
                GradientStopValue(location: 1.0, red: 0.20, green: 0.45, blue: 0.62)
            ]
        case .goldenHour:
            return [
                GradientStopValue(location: 0.0, red: 0.55, green: 0.35, blue: 0.25),
                GradientStopValue(location: 1.0, red: 0.90, green: 0.65, blue: 0.40)
            ]
        case .dusk:
            return [
                GradientStopValue(location: 0.0, red: 0.35, green: 0.25, blue: 0.45),
                GradientStopValue(location: 1.0, red: 0.12, green: 0.10, blue: 0.28)
            ]
        case .night:
            return [
                GradientStopValue(location: 0.0, red: 0.04, green: 0.06, blue: 0.14),
                GradientStopValue(location: 1.0, red: 0.08, green: 0.10, blue: 0.22)
            ]
        }
    }

    static func stops(for date: Date, calendar: Calendar = .current) -> [GradientStopValue] {
        stops(for: phase(for: date, calendar: calendar))
    }

    static func accentColor(for phase: SkyPhase) -> Color {
        switch phase {
        case .preDawn, .night, .dusk:
            Color(red: 0.45, green: 0.65, blue: 0.85)
        case .dawn, .goldenHour:
            Color(red: 0.95, green: 0.70, blue: 0.45)
        case .morning, .midday, .afternoon:
            Color(red: 0.20, green: 0.75, blue: 0.80)
        }
    }
}