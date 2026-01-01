// File: Tests/DeviceDiscoveryViewModelTests.swift

import XCTest
@testable import UniversalTVRemote

@MainActor
final class DeviceDiscoveryViewModelTests: XCTestCase {
    func testScanUpdatesDevices() async {
        let service = MockDiscoveryService(devices: [DiscoveredDevice(name: "Roku", ipAddress: "192.168.0.2", type: .roku)])
        let viewModel = DeviceDiscoveryViewModel(discoveryService: service)

        await viewModel.scan()
        XCTAssertEqual(viewModel.devices.count, 1)
        XCTAssertEqual(viewModel.devices.first?.type, .roku)
    }
}

private final class MockDiscoveryService: DeviceDiscoveryService {
    private let devices: [DiscoveredDevice]

    init(devices: [DiscoveredDevice]) {
        self.devices = devices
    }

    func scan() async -> [DiscoveredDevice] {
        devices
    }
}
