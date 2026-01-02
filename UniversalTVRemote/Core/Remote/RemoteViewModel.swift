// File: Core/Remote/RemoteViewModel.swift

import Foundation
import SwiftUI
import Combine

@MainActor
public final class RemoteViewModel: ObservableObject {
    @Published public private(set) var status: String = "Déconnecté"
    @Published public private(set) var errorMessage: String?
    @Published public var quickText: String = ""
    @Published public private(set) var streamingApps: Set<StreamingApp> = []
    @Published public private(set) var streamingAppsLoaded: Bool = false

    private let driver: TVDriver
    private let router: CommandRouting
    private var streamingProvider: StreamingAppLaunching?
    private var cancellables: Set<AnyCancellable> = []

    public var capabilities: Set<Capability> {
        driver.capabilities
    }
    public var hasStreamingProvider: Bool {
        streamingProvider != nil
    }

    public init(driver: TVDriver) {
        self.driver = driver
        self.router = CommandRouter(driver: driver)
        if let provider = driver as? StreamingAppLaunching {
            streamingProvider = provider
            provider.streamingAppsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] apps in
                    self?.streamingApps = apps
                }
                .store(in: &cancellables)
            provider.streamingAppsLoadedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] loaded in
                    self?.streamingAppsLoaded = loaded
                }
                .store(in: &cancellables)
        }
    }

    public func connect() async {
        status = "Connexion…"
        do {
            try await driver.connect()
            status = "Connecté"
        } catch {
            status = "Erreur"
            errorMessage = error.localizedDescription
        }
    }

    public func supports(_ capability: Capability) -> Bool {
        capabilities.contains(capability)
    }

    public func supports(command: RemoteCommand) -> Bool {
        switch command {
        case .power:
            return capabilities.contains(.power)
        case .home, .back, .ok, .up, .down, .left, .right, .menu:
            return capabilities.contains(.navigation)
        case .volumeUp, .volumeDown:
            return capabilities.contains(.volume)
        case .mute:
            return capabilities.contains(.mute)
        case .playPause, .play, .pause, .fastForward, .rewind:
            return capabilities.contains(.playback)
        case .channelUp, .channelDown:
            return capabilities.contains(.channel)
        case .digit(_):
            // Numeric keys are used mainly for channel entry on TVs.
            return capabilities.contains(.channel)
        case .settings:
            // On LG, settings is implemented by launching the Settings app.
            return capabilities.contains(.launcher)
        case .input, .list, .adSap:
            // These behave like navigation/remote keys.
            return capabilities.contains(.navigation)
        }
    }

    public func send(_ command: RemoteCommand) async {
        do {
            try await router.send(command: command)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func sendText() async {
        let text = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try await router.sendText(text)
            quickText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func launch(_ app: LaunchableApp) async {
        do {
            try await router.launch(app: app)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func launchStreaming(_ app: StreamingApp) async -> Bool {
        guard let streamingProvider else { return false }
        do {
            try await streamingProvider.launchStreamingApp(app)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func isStreamingAppAvailable(_ app: StreamingApp) -> Bool {
        streamingApps.contains(app)
    }
}
