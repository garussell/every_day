//
//  NetworkSession.swift
//  every_day
//
//  Protocol abstracting URLSession so services can be tested with mock data.
//

import Foundation

/// Minimal async networking contract that URLSession already satisfies.
protocol NetworkSession: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// URLSession already has these methods — just declare conformance.
extension URLSession: NetworkSession {}
