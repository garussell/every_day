//
//  MockNetworking.swift
//  every_dayTests
//
//  Provides a mock NetworkSession and MockURLProtocol for unit testing
//  services without hitting the network.
//

import Foundation
@testable import every_day

// MARK: - MockURLProtocol

/// A URLProtocol subclass that intercepts all requests and returns
/// pre-configured stub data. Configure via the static properties
/// before each test.
final class MockURLProtocol: URLProtocol {

    /// Handler called for every intercepted request.
    /// Return `(Data, HTTPURLResponse)` for success, or throw for failure.
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - MockNetworkSession

/// A concrete NetworkSession backed by a URLSession configured with MockURLProtocol.
/// Use this in service init to intercept all requests in tests.
struct MockNetworkSession: NetworkSession {
    let session: URLSession

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
    }

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await session.data(from: url)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

// MARK: - Helpers

extension MockURLProtocol {
    /// Convenience: configure a fixed JSON response for any request.
    static func stub(json: String, statusCode: Int = 200) {
        requestHandler = { request in
            let data = Data(json.utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (data, response)
        }
    }

    /// Convenience: configure any request to fail with the given error.
    static func stubError(_ error: Error) {
        requestHandler = { _ in throw error }
    }
}
