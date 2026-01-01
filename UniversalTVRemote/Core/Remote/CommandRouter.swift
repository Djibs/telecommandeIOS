// File: Core/Remote/CommandRouter.swift

import Foundation
import OSLog

public protocol CommandRouting {
    func send(command: RemoteCommand) async throws
    func sendText(_ text: String) async throws
    func launch(app: LaunchableApp) async throws
    func castMedia(url: URL, type: MediaType) async throws
}

public final class CommandRouter: CommandRouting {
    private let driver: TVDriver
    private let logger = AppLogger.driver
    private static let timestampFormatter = ISO8601DateFormatter()

    public init(driver: TVDriver) {
        self.driver = driver
    }

    public func send(command: RemoteCommand) async throws {
        let start = Date()
        let startTimestamp = Self.timestampFormatter.string(from: start)
        AppLogger.debugIfVerbose("Début commande \(command) à \(startTimestamp)", logger: logger)
        if let required = capability(for: command), !driver.capabilities.contains(required) {
            logger.warning("Capability manquante \(required.rawValue, privacy: .public) pour commande \(String(describing: command), privacy: .public)")
        }
        do {
            try await driver.send(command: command)
            let end = Date()
            let endTimestamp = Self.timestampFormatter.string(from: end)
            let latency = end.timeIntervalSince(start)
            logger.info("Commande \(String(describing: command), privacy: .public) envoyée en \(String(format: "%.2f", latency), privacy: .public)s")
            AppLogger.debugIfVerbose("Fin commande \(command) à \(endTimestamp)", logger: logger)
        } catch {
            logger.error("Erreur commande \(String(describing: command), privacy: .public) vers \(driver.device.ipAddress, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    public func sendText(_ text: String) async throws {
        let start = Date()
        let length = text.count
        AppLogger.debugIfVerbose("Début sendText (\(length, privacy: .public) caractères)", logger: logger)
        if !driver.capabilities.contains(.textInput) {
            logger.warning("Capability manquante textInput pour sendText (\(length, privacy: .public) caractères)")
        }
        do {
            try await driver.sendText(text)
            let latency = Date().timeIntervalSince(start)
            logger.info("sendText envoyé (\(length, privacy: .public) caractères) en \(String(format: "%.2f", latency), privacy: .public)s")
        } catch {
            logger.error("Erreur sendText vers \(driver.device.ipAddress, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    public func launch(app: LaunchableApp) async throws {
        let start = Date()
        AppLogger.debugIfVerbose("Début launch \(app.rawValue, privacy: .public)", logger: logger)
        if !driver.capabilities.contains(.launcher) {
            logger.warning("Capability manquante launcher pour launch \(app.rawValue, privacy: .public)")
        }
        do {
            try await driver.launch(app: app)
            let latency = Date().timeIntervalSince(start)
            logger.info("launch \(app.rawValue, privacy: .public) en \(String(format: "%.2f", latency), privacy: .public)s")
        } catch {
            logger.error("Erreur launch \(app.rawValue, privacy: .public) vers \(driver.device.ipAddress, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        let start = Date()
        AppLogger.debugIfVerbose("Début cast \(type.rawValue, privacy: .public)", logger: logger)
        if !driver.capabilities.contains(.casting) {
            logger.warning("Capability manquante casting pour cast \(type.rawValue, privacy: .public)")
        }
        do {
            try await driver.castMedia(url: url, type: type)
            let latency = Date().timeIntervalSince(start)
            logger.info("cast \(type.rawValue, privacy: .public) en \(String(format: "%.2f", latency), privacy: .public)s")
        } catch {
            logger.error("Erreur cast \(type.rawValue, privacy: .public) vers \(driver.device.ipAddress, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func capability(for command: RemoteCommand) -> Capability? {
        switch command {
        case .power:
            return .power
        case .home, .back, .ok, .up, .down, .left, .right, .menu:
            return .navigation
        case .volumeUp, .volumeDown:
            return .volume
        case .mute:
            return .mute
        case .playPause, .play, .pause, .fastForward, .rewind:
            return .playback
        case .channelUp, .channelDown:
            return .channel
        }
    }
}
