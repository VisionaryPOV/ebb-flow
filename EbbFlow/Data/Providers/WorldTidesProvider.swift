import Foundation

struct WorldTidesResponse: Decodable, Sendable {
    let status: Int?
    let heights: [WorldTidesHeight]?
    let extremes: [WorldTidesExtreme]?
}

struct WorldTidesHeight: Decodable, Sendable {
    let dt: Int
    let height: Double
}

struct WorldTidesExtreme: Decodable, Sendable {
    let dt: Int
    let height: Double
    let type: String
}

struct WorldTidesProvider: TidePredictionFetching, Sendable {
    private let session: URLSession
    private let apiKey: String
    private let baseURL: URL

    init(
        session: URLSession = .shared,
        apiKey: String = "",
        baseURL: URL = URL(string: "https://www.worldtides.info/api/v3")!
    ) {
        self.session = session
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    func supports(latitude: Double, longitude: Double) -> Bool {
        !apiKey.isEmpty
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        try await fetchJSON(stationID: stationID, from: from, to: to, includeExtremes: true, includeHeights: false)
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        try await fetchJSON(stationID: stationID, from: from, to: to, includeExtremes: false, includeHeights: true)
    }

    private func fetchJSON(
        stationID: String,
        from: Date,
        to: Date,
        includeExtremes: Bool,
        includeHeights: Bool
    ) async throws -> Data {
        guard !apiKey.isEmpty else { throw TideServiceError.invalidRequest }

        let parts = stationID.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]) else {
            throw TideServiceError.invalidRequest
        }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "localtime", value: nil)
        ]
        if includeExtremes { queryItems.append(URLQueryItem(name: "extremes", value: nil)) }
        if includeHeights { queryItems.append(URLQueryItem(name: "heights", value: nil)) }
        components?.queryItems = queryItems

        guard let url = components?.url else { throw TideServiceError.invalidRequest }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TideServiceError.networkFailure
        }

        let worldTides = try JSONDecoder().decode(WorldTidesResponse.self, from: data)
        return try convertToNOAAFormat(worldTides, includeExtremes: includeExtremes, includeHeights: includeHeights)
    }

    private func convertToNOAAFormat(
        _ response: WorldTidesResponse,
        includeExtremes: Bool,
        includeHeights: Bool
    ) throws -> Data {
        var predictions: [[String: String]] = []

        if includeExtremes, let extremes = response.extremes {
            for extreme in extremes {
                let date = Date(timeIntervalSince1970: TimeInterval(extreme.dt))
                predictions.append([
                    "t": TideDataTransformer.makePredictionDateFormatter(timeZone: .current).string(from: date),
                    "v": String(format: "%.3f", extreme.height),
                    "type": extreme.type == "High" ? "H" : "L"
                ])
            }
        }

        if includeHeights, let heights = response.heights {
            for height in heights {
                let date = Date(timeIntervalSince1970: TimeInterval(height.dt))
                predictions.append([
                    "t": TideDataTransformer.makePredictionDateFormatter(timeZone: .current).string(from: date),
                    "v": String(format: "%.3f", height.height)
                ])
            }
        }

        let wrapper = ["predictions": predictions]
        return try JSONSerialization.data(withJSONObject: wrapper)
    }
}

struct CompositeTideProviderRouter: TidePredictionFetching, Sendable {
    private let noaa: NOAADataGetterClient
    private let worldTides: WorldTidesProvider

    init(noaa: NOAADataGetterClient = NOAADataGetterClient(), worldTides: WorldTidesProvider = WorldTidesProvider()) {
        self.noaa = noaa
        self.worldTides = worldTides
    }

    func fetchExtremes(stationID: String, from: Date, to: Date) async throws -> Data {
        if stationID.contains(",") {
            return try await worldTides.fetchExtremes(stationID: stationID, from: from, to: to)
        }
        return try await noaa.fetchExtremes(stationID: stationID, from: from, to: to)
    }

    func fetchHeights(stationID: String, from: Date, to: Date, intervalMinutes: Int) async throws -> Data {
        if stationID.contains(",") {
            return try await worldTides.fetchHeights(stationID: stationID, from: from, to: to, intervalMinutes: intervalMinutes)
        }
        return try await noaa.fetchHeights(stationID: stationID, from: from, to: to, intervalMinutes: intervalMinutes)
    }
}