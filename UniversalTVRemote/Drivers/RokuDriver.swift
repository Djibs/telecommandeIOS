// File: Drivers/RokuDriver.swift

import Foundation

public final class RokuDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [.power, .volume, .mute, .navigation, .playback, .channel, .textInput, .launcher]

    private let httpClient: HTTPClient

    public init(device: DiscoveredDevice, httpClient: HTTPClient) {
        self.device = device
        self.httpClient = httpClient
    }

    public func connect() async throws {
        // Roku ECP ne nécessite pas de pairing explicite.
    }

    public func disconnect() {}

    public func send(command: RemoteCommand) async throws {
        let path: String
        switch command {
        case .power: path = "Power"
        case .home: path = "Home"
        case .back: path = "Back"
        case .ok: path = "Select"
        case .up: path = "Up"
        case .down: path = "Down"
        case .left: path = "Left"
        case .right: path = "Right"
        case .menu: path = "Info"
        case .volumeUp: path = "VolumeUp"
        case .volumeDown: path = "VolumeDown"
        case .mute: path = "VolumeMute"
        case .playPause: path = "Play"
        case .play: path = "Play"
        case .pause: path = "Play"
        case .fastForward: path = "Fwd"
        case .rewind: path = "Rev"
        case .channelUp: path = "ChannelUp"
        case .channelDown: path = "ChannelDown"
        case .digit(let n):
            guard (0...9).contains(n) else { throw RemoteError.unsupported }
            path = "Lit_\(n)"
        default:
            throw RemoteError.unsupported
        }
        let url = baseURL.appendingPathComponent("keypress/")
            .appendingPathComponent(path)
        _ = try await httpClient.post(url: url, body: nil, timeout: 3)
    }

    public func sendText(_ text: String) async throws {
        guard !text.isEmpty else { return }
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        let url = baseURL.appendingPathComponent("keypress/Lit_")
            .appendingPathComponent(encoded)
        _ = try await httpClient.post(url: url, body: nil, timeout: 3)
    }

    public func launch(app: LaunchableApp) async throws {
        let appId = appIdFor(app)
        guard let appId else { throw RemoteError.unsupported }
        let url = baseURL.appendingPathComponent("launch/")
            .appendingPathComponent(appId)
        _ = try await httpClient.post(url: url, body: nil, timeout: 3)
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        // Roku ECP peut utiliser /input? pour certaines apps. Nécessite une app channel dédiée.
        // TODO: intégrer le lancement d'une app compatible (ex: Roku Media Player) avec paramètres.
        throw RemoteError.unsupported
    }

    private var baseURL: URL {
        let host = device.ipAddress
        let port = device.port ?? 8060
        return URL(string: "http://\(host):\(port)/")!
    }

    private func appIdFor(_ app: LaunchableApp) -> String? {
        // TODO: rendre configurable via metadata/registry.
        switch app {
        case .netflix:
            return "12"
        case .primeVideo:
            return "13"
        case .youtube:
            return "837"
        case .disneyPlus:
            return "291097"
        case .plex:
            return "13535"
        }
    }
}
