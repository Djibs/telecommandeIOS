// File: Core/Networking/WebSocketClient.swift

import Foundation

public protocol WebSocketClient {
    func connect() async throws
    func disconnect()
    func send(text: String) async throws
}

public final class URLSessionWebSocketClient: WebSocketClient {
    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func connect() async throws {
        let task = session.webSocketTask(with: url)
        task.resume()
        self.task = task
    }

    public func disconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    public func send(text: String) async throws {
        guard let task else { throw RemoteError.connectionFailed }
        try await task.send(.string(text))
    }
}
