// File: Drivers/LGWebOSDriver.swift

import Foundation
import WebOSClient
import Combine
import OSLog

public final class LGWebOSDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [
        .navigation,
        .volume,
        .mute,
        .playback,
        .channel,
        .textInput,
        .launcher,
        .touchpad
    ]

    let controller: LGWebOSControlling
    private let appResolver: LGAppResolver
    private let logger = AppLogger.lgWebOS

    public init(device: DiscoveredDevice, controller: LGWebOSControlling? = nil, appResolver: LGAppResolver? = nil) {
        self.device = device
        if let controller {
            self.controller = controller
        } else {
            self.controller = LGWebOSService(device: device)
        }
        if let appResolver {
            self.appResolver = appResolver
        } else if let requestable = self.controller as? LGWebOSRequesting {
            self.appResolver = LGAppResolver(service: requestable)
        } else {
            self.appResolver = LGAppResolver(service: LGWebOSService(device: device))
        }
    }

    public var service: LGWebOSService? {
        controller as? LGWebOSService
    }

    public var requiresPairing: Bool {
        !controller.hasStoredClientKey
    }

    public func connect() async throws {
        logger.info("LGWebOSDriver connect \(device.ipAddress, privacy: .public)")
        try await controller.ensureReady(pairingType: nil)
        Task {
            try? await appResolver.refreshInstalledApps()
        }
    }

    public func disconnect() {
        logger.info("LGWebOSDriver disconnect \(device.ipAddress, privacy: .public)")
        controller.disconnect()
    }

    public func send(command: RemoteCommand) async throws {
        AppLogger.debugIfVerbose("LGWebOS send command \(String(describing: command), privacy: .public)", logger: logger)
        switch command {
        case .power:
            controller.send(.turnOff)
        case .home:
            controller.sendKey(.home)
        case .back:
            controller.sendKey(.back)
        case .ok:
            controller.sendKey(.enter)
        case .up:
            controller.sendKey(.up)
        case .down:
            controller.sendKey(.down)
        case .left:
            controller.sendKey(.left)
        case .right:
            controller.sendKey(.right)
        case .menu:
            controller.sendKey(.menu)
        case .volumeUp:
            controller.send(.volumeUp)
        case .volumeDown:
            controller.send(.volumeDown)
        case .mute:
            controller.sendKey(.mute)
        case .playPause:
            controller.send(.play)
        case .play:
            controller.send(.play)
        case .pause:
            controller.send(.pause)
        case .fastForward:
            controller.send(.fastForward)
        case .rewind:
            controller.send(.rewind)
        case .channelUp:
            controller.send(.channelUp)
        case .channelDown:
            controller.send(.channelDown)
        }
    }

    public func sendText(_ text: String) async throws {
        guard !text.isEmpty else { return }
        logger.info("LGWebOS sendText (\(text.count, privacy: .public) caractères)")
        controller.send(.insertText(text: text, replace: true))
        controller.send(.sendEnterKey)
    }

    public func launch(app: LaunchableApp) async throws {
        if let streamingApp = streamingAppFor(app) {
            logger.info("LGWebOS launch streaming \(streamingApp.rawValue, privacy: .public)")
            try await appResolver.launch(streamingApp: streamingApp)
            return
        }
        guard let appId = appIdFor(app) else { throw RemoteError.unsupported }
        logger.info("LGWebOS launch appId \(appId, privacy: .public)")
        controller.send(.launchApp(appId: appId))
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        throw RemoteError.unsupported
    }

    private func appIdFor(_ app: LaunchableApp) -> String? {
        switch app {
        case .netflix, .primeVideo, .youtube, .disneyPlus:
            return nil
        case .plex:
            return "plex"
        }
    }

    private func streamingAppFor(_ app: LaunchableApp) -> StreamingApp? {
        switch app {
        case .netflix:
            return .netflix
        case .primeVideo:
            return .primeVideo
        case .youtube:
            return .youtube
        case .disneyPlus:
            return .disneyPlus
        case .plex:
            return nil
        }
    }
}

extension LGWebOSDriver: StreamingAppLaunching {
    public var streamingApps: Set<StreamingApp> {
        appResolver.availableApps
    }

    public var isStreamingAppsLoaded: Bool {
        appResolver.isLoaded
    }

    public var streamingAppsPublisher: AnyPublisher<Set<StreamingApp>, Never> {
        appResolver.$availableApps.eraseToAnyPublisher()
    }

    public var streamingAppsLoadedPublisher: AnyPublisher<Bool, Never> {
        appResolver.$isLoaded.eraseToAnyPublisher()
    }

    public func launchStreamingApp(_ app: StreamingApp) async throws {
        try await appResolver.launch(streamingApp: app)
    }
}
