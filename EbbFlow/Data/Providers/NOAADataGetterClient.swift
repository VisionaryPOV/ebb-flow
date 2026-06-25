import Foundation

protocol TidePredictionFetching: Sendable {
    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data
    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data
}

struct NOAADataGetterClient: TidePredictionFetching, Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let applicationName: String

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter")!,
        applicationName: String = "EbbAndFlow"
    ) {
        self.session = session
        self.baseURL = baseURL
        self.applicationName = applicationName
    }

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        try await fetch(
            stationID: stationID,
            from: from,
            to: to,
            interval: "hilo",
            timeZone: timeZone
        )
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int = 15,
        timeZone: TimeZone
    ) async throws -> Data {
        try await fetch(
            stationID: stationID,
            from: from,
            to: to,
            interval: String(intervalMinutes),
            timeZone: timeZone
        )
    }

    private func fetch(
        stationID: String,
        from: Date,
        to: Date,
        interval: String,
        timeZone: TimeZone
    ) async throws -> Data {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "station", value: stationID),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "begin_date", value: Self.queryDate(from, timeZone: timeZone)),
            URLQueryItem(name: "end_date", value: Self.queryDate(to, timeZone: timeZone)),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "units", value: "english"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "application", value: applicationName)
        ]

        guard let url = components?.url else {
            throw TideServiceError.invalidRequest
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TideServiceError.networkFailure
        }
        try Self.validatePredictionsPayload(data)
        return data
    }

    static func validatePredictionsPayload(_ data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TideServiceError.parseFailure
        }
        if json["error"] != nil {
            throw TideServiceError.parseFailure
        }
        guard let predictions = json["predictions"] as? [Any], !predictions.isEmpty else {
            throw TideServiceError.parseFailure
        }
    }

    static func queryDate(_ date: Date, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}

enum TideServiceError: Error, Equatable, Sendable {
    case invalidRequest
    case networkFailure
    case parseFailure
    case cacheMiss
}