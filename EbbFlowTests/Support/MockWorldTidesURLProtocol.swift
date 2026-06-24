import Foundation

final class MockWorldTidesURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var receivedURLs: [URL] = []

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host?.contains("worldtides.info") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.receivedURLs.append(url)

        let response = HTTPURLResponse(
            url: url,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

enum MockWorldTidesURLSessionFactory {
    static func make() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockWorldTidesURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func reset() {
        MockWorldTidesURLProtocol.responseData = Data()
        MockWorldTidesURLProtocol.statusCode = 200
        MockWorldTidesURLProtocol.receivedURLs = []
    }
}