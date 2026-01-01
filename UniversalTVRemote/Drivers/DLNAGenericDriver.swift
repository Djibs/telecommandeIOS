// File: Drivers/DLNAGenericDriver.swift

import Foundation

public final class DLNAGenericDriver: TVDriver {
    public let device: DiscoveredDevice
    public let capabilities: Set<Capability> = [.casting]

    private let httpClient: HTTPClient

    public init(device: DiscoveredDevice, httpClient: HTTPClient) {
        self.device = device
        self.httpClient = httpClient
    }

    public func connect() async throws {
        // DLNA UPnP ne nécessite pas de pairing.
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
        // TODO: implémenter SOAP AVTransport SetAVTransportURI + Play.
        throw RemoteError.unsupported
    }
}
