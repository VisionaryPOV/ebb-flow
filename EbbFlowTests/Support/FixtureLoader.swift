import Foundation

enum FixtureLoader {
    static func data(named name: String) throws -> Data {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw FixtureError.missing(name)
        }
        return try Data(contentsOf: url)
    }
}

private final class BundleToken: NSObject {}

enum FixtureError: Error {
    case missing(String)
}