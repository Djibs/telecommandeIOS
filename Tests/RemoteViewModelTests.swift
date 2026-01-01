// File: Tests/RemoteViewModelTests.swift

import XCTest
@testable import UniversalTVRemote

@MainActor
final class RemoteViewModelTests: XCTestCase {
    func testSendCommandUpdatesErrorOnFailure() async {
        let driver = MockFailingDriver(device: DiscoveredDevice(name: "Test", ipAddress: "127.0.0.1", type: .unknown))
        let viewModel = RemoteViewModel(driver: driver)

        await viewModel.send(.home)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

private final class MockFailingDriver: TVDriver {
    let device: DiscoveredDevice
    let capabilities: Set<Capability> = []

    init(device: DiscoveredDevice) {
        self.device = device
    }

    func connect() async throws { throw RemoteError.connectionFailed }
    func disconnect() {}
    func send(command: RemoteCommand) async throws { throw RemoteError.unsupported }
    func sendText(_ text: String) async throws { throw RemoteError.unsupported }
    func launch(app: LaunchableApp) async throws { throw RemoteError.unsupported }
    func castMedia(url: URL, type: MediaType) async throws { throw RemoteError.unsupported }
}
