import Foundation

struct CatalogTideFallbackProvider: TidePredictionFetching, Sendable {
    private let loader: @Sendable (String) throws -> Data

    init(loader: @escaping @Sendable (String) throws -> Data = CatalogTideFallbackProvider.bundleLoader) {
        self.loader = loader
    }

    func fetchExtremes(stationID: String, from: Date, to: Date, timeZone: TimeZone) async throws -> Data {
        try await fetchFixture(stationID: stationID, resource: extremesResource)
    }

    func fetchHeights(
        stationID: String,
        from: Date,
        to: Date,
        intervalMinutes: Int,
        timeZone: TimeZone
    ) async throws -> Data {
        try await fetchFixture(stationID: stationID, resource: heightsResource)
    }

    private func fetchFixture(stationID: String, resource: (String) -> String?) async throws -> Data {
        guard TideStationCatalog.resolve(id: stationID) != nil else {
            throw TideServiceError.cacheMiss
        }
        guard let name = resource(stationID) else {
            throw TideServiceError.cacheMiss
        }
        return try loader(name)
    }

    private func extremesResource(for stationID: String) -> String? {
        switch stationID {
        case "9410840": "marina_del_rey_hilo"
        default: nil
        }
    }

    private func heightsResource(for stationID: String) -> String? {
        switch stationID {
        case "9410840": "marina_del_rey_heights"
        default: nil
        }
    }

    static func bundleLoader(named name: String) throws -> Data {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") else {
            throw TideServiceError.cacheMiss
        }
        return try Data(contentsOf: url)
    }
}