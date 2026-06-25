import CoreLocation
import Foundation

enum NOAAStationDiscovery {
    static let referencePreferenceMeters: Double = 5_000

    static func filter(
        stations: [NOAAStationRecord],
        query: String,
        limit: Int = 50
    ) -> [NOAAStationRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let tokens = trimmed.lowercased().split(separator: " ").map(String.init)
        var matches = stations.filter { record in
            let haystack = [
                record.name,
                record.state,
                record.id
            ].joined(separator: " ").lowercased()
            return tokens.allSatisfy { haystack.contains($0) }
        }

        if matches.isEmpty, let regionMatches = regionMatches(for: trimmed.lowercased(), in: stations) {
            matches = regionMatches
        }

        return Array(
            matches
                .sorted { lhs, rhs in
                    if lhs.isReferenceStation != rhs.isReferenceStation {
                        return lhs.isReferenceStation
                    }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                .prefix(limit)
        )
    }

    static func nearest(
        stations: [NOAAStationRecord],
        to coordinate: CLLocationCoordinate2D,
        limit: Int = 3
    ) -> [(record: NOAAStationRecord, distanceMeters: Double)] {
        let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let ranked = stations.map { record -> (NOAAStationRecord, Double) in
            let location = CLLocation(latitude: record.lat, longitude: record.lng)
            return (record, target.distance(from: location))
        }
        .sorted { lhs, rhs in
            if abs(lhs.1 - rhs.1) <= referencePreferenceMeters {
                if lhs.0.isReferenceStation != rhs.0.isReferenceStation {
                    return lhs.0.isReferenceStation
                }
            }
            return lhs.1 < rhs.1
        }

        return Array(ranked.prefix(limit)).map { ($0.0, $0.1) }
    }

    static func states(from stations: [NOAAStationRecord]) -> [(state: String, count: Int)] {
        Dictionary(grouping: stations, by: \.state)
            .map { state, records in
                (state: state.isEmpty ? "Territories" : state, count: records.count)
            }
            .sorted { lhs, rhs in
                if lhs.state == "Territories" { return false }
                if rhs.state == "Territories" { return true }
                return lhs.state < rhs.state
            }
    }

    static func stations(
        inState state: String,
        from stations: [NOAAStationRecord]
    ) -> [NOAAStationRecord] {
        let key = state == "Territories" ? "" : state
        return stations
            .filter { $0.state == key }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    static func timeZone(for record: NOAAStationRecord) -> TimeZone {
        if let identifier = timeZoneIdentifier(for: record.state) {
            return TimeZone(identifier: identifier) ?? fallbackTimeZone(for: record)
        }
        return fallbackTimeZone(for: record)
    }

    static func timeZoneIdentifier(for state: String) -> String? {
        switch state {
        case "CA", "OR", "WA", "NV":
            "America/Los_Angeles"
        case "AK":
            "America/Anchorage"
        case "HI":
            "Pacific/Honolulu"
        case "TX", "LA", "MS", "AL", "TN", "KY", "IN", "MI", "OH", "WI", "IL", "MO", "AR", "IA", "MN", "ND", "SD", "NE", "KS", "OK":
            "America/Chicago"
        case "FL", "GA", "SC", "NC", "VA", "MD", "DE", "NJ", "PA", "NY", "CT", "RI", "MA", "VT", "NH", "ME", "DC", "WV":
            "America/New_York"
        case "GU":
            "Pacific/Guam"
        case "AS":
            "Pacific/Pago_Pago"
        case "PR", "VI":
            "America/Puerto_Rico"
        default:
            nil
        }
    }

    private static func regionMatches(for query: String, in stations: [NOAAStationRecord]) -> [NOAAStationRecord]? {
        guard let bounds = regionBounds[query] else { return nil }
        return stations.filter { record in
            record.lat >= bounds.minLat && record.lat <= bounds.maxLat
                && record.lng >= bounds.minLng && record.lng <= bounds.maxLng
        }
    }

    private static let regionBounds: [String: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)] = [
        "maui": (20.45, 21.05, -156.75, -155.85)
    ]

    private static func fallbackTimeZone(for record: NOAAStationRecord) -> TimeZone {
        if let offset = record.timezonecorr {
            return TimeZone(secondsFromGMT: offset * 3_600) ?? TideDataTransformer.noaaLocalTimeZone
        }
        return TideDataTransformer.noaaLocalTimeZone
    }
}