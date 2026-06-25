import Foundation

protocol NOAAStationFetching: Sendable {
    func allStations() async throws -> [NOAAStationRecord]
}

struct NOAAStationMetadataClient: NOAAStationFetching, Sendable {
    private let session: URLSession
    private let cacheURL: URL
    private let metadataURL: URL
    private let cacheTTL: TimeInterval

    init(
        session: URLSession = .shared,
        metadataURL: URL = URL(string: "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=tidepredictions")!,
        cacheURL: URL? = nil,
        cacheTTL: TimeInterval = 24 * 60 * 60
    ) {
        self.session = session
        self.metadataURL = metadataURL
        self.cacheTTL = cacheTTL
        if let cacheURL {
            self.cacheURL = cacheURL
        } else {
            let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.cacheURL = base.appendingPathComponent("noaa_tide_stations.json")
        }
    }

    func allStations() async throws -> [NOAAStationRecord] {
        if let cached = try loadCachedStations(), !cached.isEmpty {
            TideStationCatalog.register(cached)
            return cached
        }

        let (data, response) = try await session.data(from: metadataURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TideServiceError.networkFailure
        }

        let decoded = try JSONDecoder().decode(NOAAStationListResponse.self, from: data)
        try persistCache(data)
        TideStationCatalog.register(decoded.stations)
        return decoded.stations
    }

    private func loadCachedStations() throws -> [NOAAStationRecord]? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else { return nil }
        let attributes = try FileManager.default.attributesOfItem(atPath: cacheURL.path)
        if let modified = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) > cacheTTL {
            return nil
        }
        let data = try Data(contentsOf: cacheURL)
        return try JSONDecoder().decode(NOAAStationListResponse.self, from: data).stations
    }

    private func persistCache(_ data: Data) throws {
        try data.write(to: cacheURL, options: .atomic)
    }
}

struct FixtureNOAAStationFetcher: NOAAStationFetching, Sendable {
    let stations: [NOAAStationRecord]

    func allStations() async throws -> [NOAAStationRecord] {
        TideStationCatalog.register(stations)
        return stations
    }
}