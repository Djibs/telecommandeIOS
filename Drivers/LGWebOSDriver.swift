// File: Drivers/LGWebOSDriver.swift

import Foundation

public final class LGWebOSDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [.navigation, .volume, .mute, .launcher, .textInput]

    public init(device: DiscoveredDevice) {
        self.device = device
    }

    public func connect() async throws {
        // TODO: implémenter pairing webOS (ws://<ip>:3000/) avec register et stockage token.
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
