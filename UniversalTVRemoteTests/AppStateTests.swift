// File: Tests/AppStateTests.swift

import XCTest
@testable import UniversalTVRemote

final class AppStateTests: XCTestCase {
    @MainActor
    func testPersistLastLGDeviceStoresNameAndIP() {
        let suiteName = "AppStateTests"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let appState = AppState(
            discoveryService: DummyDiscoveryService(),
            driverRegistry: DummyDriverRegistry(),
            userDefaults: defaults
        )

        let lgDevice = DiscoveredDevice(
            name: "Salon LG",
            ipAddress: "192.168.0.12",
            type: .lgWebOS
        )
        appState.selectedDevice = lgDevice

        XCTAssertEqual(defaults.string(forKey: AppSettingsKeys.lastLGDeviceName), "Salon LG")
        XCTAssertEqual(defaults.string(forKey: AppSettingsKeys.lastLGDeviceIP), "192.168.0.12")

        let rokuDevice = DiscoveredDevice(
            name: "Roku",
            ipAddress: "10.0.0.10",
            type: .roku
        )
        appState.selectedDevice = rokuDevice

        XCTAssertEqual(defaults.string(forKey: AppSettingsKeys.lastLGDeviceName), "Salon LG")
        XCTAssertEqual(defaults.string(forKey: AppSettingsKeys.lastLGDeviceIP), "192.168.0.12")
    }
}

private struct DummyDiscoveryService: DeviceDiscoveryService {
    func scan() async -> [DiscoveredDevice] {
        []
    }
}

private struct DummyDriverRegistry: DriverRegistry {
    func driver(for device: DiscoveredDevice) -> TVDriver {
        StubDriver(device: device)
    }
}
