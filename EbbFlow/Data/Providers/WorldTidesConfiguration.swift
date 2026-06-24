import Foundation

enum WorldTidesConfiguration: Sendable {
    static var apiKey: String {
        if let key = ProcessInfo.processInfo.environment["WORLDTIDES_API_KEY"], !key.isEmpty {
            return key
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "WorldTidesAPIKey") as? String, !key.isEmpty {
            return key
        }
        return ""
    }

    static var isConfigured: Bool {
        !apiKey.isEmpty
    }
}