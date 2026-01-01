// File: Core/Networking/HTTPClient.swift

import Foundation

public protocol HTTPClient {
    func get(url: URL, timeout: TimeInterval) async throws -> Data
    func post(url: URL, body: Data?, timeout: TimeInterval) async throws -> Data
}

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(url: URL, timeout: TimeInterval = 5) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    public func post(url: URL, body: Data?, timeout: TimeInterval = 5) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return data
    }

    private func validate(response: URLResponse) throws {
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw RemoteError.network("HTTP \(httpResponse.statusCode)")
        }
    }
}
