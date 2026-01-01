// File: Drivers/TVDriver.swift

import Foundation

public protocol TVDriver {
    var device: DiscoveredDevice { get }
    var capabilities: Set<Capability> { get }
    func connect() async throws
    func disconnect()
    func send(command: RemoteCommand) async throws
    func sendText(_ text: String) async throws
    func launch(app: LaunchableApp) async throws
    func castMedia(url: URL, type: MediaType) async throws
}
