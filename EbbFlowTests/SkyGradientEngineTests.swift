import Foundation
import Testing
@testable import EbbFlow

struct SkyGradientEngineTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }()

    @Test func dawnPhaseAtSixAM() throws {
        let date = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 6))!
        let phase = SkyGradientEngine.phase(for: date, calendar: Self.calendar)
        #expect(phase == .dawn)
    }

    @Test func middayPhaseAtNoon() throws {
        let date = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 12))!
        let phase = SkyGradientEngine.phase(for: date, calendar: Self.calendar)
        #expect(phase == .midday)
    }

    @Test func duskPhaseAtEightPM() throws {
        let date = Self.calendar.date(from: DateComponents(year: 2025, month: 6, day: 24, hour: 20))!
        let phase = SkyGradientEngine.phase(for: date, calendar: Self.calendar)
        #expect(phase == .dusk)
    }

    @Test func gradientStopsAreOrderedAndWithinUnitRange() throws {
        for phase in SkyPhase.allCases {
            let stops = SkyGradientEngine.stops(for: phase)
            #expect(stops.count == 2)
            #expect(stops[0].location == 0.0)
            #expect(stops[1].location == 1.0)
            #expect(stops.allSatisfy { (0...1).contains($0.red) })
            #expect(stops.allSatisfy { (0...1).contains($0.green) })
            #expect(stops.allSatisfy { (0...1).contains($0.blue) })
        }
    }

    @Test func middayStopsAreBluerThanGoldenHour() throws {
        let midday = SkyGradientEngine.stops(for: .midday)
        let golden = SkyGradientEngine.stops(for: .goldenHour)
        #expect(midday[0].blue > golden[0].blue)
    }
}