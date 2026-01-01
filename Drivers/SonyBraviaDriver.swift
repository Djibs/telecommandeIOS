// File: Drivers/SonyBraviaDriver.swift

import Foundation

public final class SonyBraviaDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [.navigation, .volume, .mute, .launcher]

    private let httpClient: HTTPClient

    public init(device: DiscoveredDevice, httpClient: HTTPClient) {
        self.device = device
        self.httpClient = httpClient
    }

    public func connect() async throws {
        // TODO: Implémenter JSON-RPC ("/sony/system", "setPowerStatus", etc.).
        throw RemoteError.pairingRequired
    }

    public func disconnect() {}

    public func send(command: RemoteCommand) async throws {
        throw RemoteError.unsupported
    }

    public func sendText(_ text: String) async throws {
        throw RemoteError.unsupported
    }

    public func launch(app: LaunchableApp) async throws {
        throw RemoteError.unsupported
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        throw RemoteError.unsupported
    }
}
