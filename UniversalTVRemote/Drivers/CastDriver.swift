// File: Drivers/CastDriver.swift

import Foundation

public final class CastDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [.casting, .launcher]

    public init(device: DiscoveredDevice) {
        self.device = device
    }

    public func connect() async throws {
        // TODO: intégrer Google Cast SDK (GCKSessionManager) et connecter l'appareil sélectionné.
    }

    public func disconnect() {}

    public func send(command: RemoteCommand) async throws {
        throw RemoteError.unsupported
    }

    public func sendText(_ text: String) async throws {
        throw RemoteError.unsupported
    }

    public func launch(app: LaunchableApp) async throws {
        // TODO: utiliser GCKDiscoveryManager + GCKSessionManager.
        throw RemoteError.unsupported
    }

    public func castMedia(url: URL, type: MediaType) async throws {
        // TODO: utiliser GCKRemoteMediaClient.loadMedia.
        throw RemoteError.unsupported
    }
}
