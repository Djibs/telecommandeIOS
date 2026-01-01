// File: Core/Remote/CommandRouter.swift

import Foundation

public protocol CommandRouting {
    func send(command: RemoteCommand) async throws
    func sendText(_ text: String) async throws
    func launch(app: LaunchableApp) async throws
    func castMedia(url: URL, type: MediaType) async throws
}

public final class CommandRouter: CommandRouting {
    private let driver: TVDriver
    private let logger: (String) -> Void

    public init(driver: TVDriver, logger: @escaping (String) -> Void = { _ in }) {
        self.driver = driver
        self.logger = logger
    }

    public func send(command: RemoteCommand) async throws {
        let start = Date()
        try await driver.send(command: command)
        let latency = Date().timeIntervalSince(start)
        logger("Commande \(command) envoyée en \(String(format: "%.2f", latency))s")
    }

    public func sendText(_ text: String) async throws {
        try await driver.sendText(text)
    }

    public func launch(app: LaunchableApp) async throws {
        try await driver.launch(app: app)
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        try await driver.castMedia(url: url, type: type)
    }
}
