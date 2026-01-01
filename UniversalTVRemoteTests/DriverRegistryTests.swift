// File: Tests/DriverRegistryTests.swift

import XCTest
@testable import UniversalTVRemote

final class DriverRegistryTests: XCTestCase {
    func testRokuDeviceSelectsRokuDriver() {
        let registry = DefaultDriverRegistry(httpClient: MockHTTPClient())
        let device = DiscoveredDevice(name: "Roku", ipAddress: "192.168.1.10", type: .roku)
        let driver = registry.driver(for: device)
        XCTAssertTrue(driver is RokuDriver)
    }

    func testUnknownDeviceSelectsStubDriver() {
        let registry = DefaultDriverRegistry(httpClient: MockHTTPClient())
        let device = DiscoveredDevice(name: "Unknown", ipAddress: "192.168.1.11", type: .unknown)
        let driver = registry.driver(for: device)
        XCTAssertTrue(driver is StubDriver)
    }
}

private final class MockHTTPClient: HTTPClient {
    func get(url: URL, timeout: TimeInterval) async throws -> Data {
        Data()
    }

    func post(url: URL, body: Data?, timeout: TimeInterval) async throws -> Data {
        Data()
    }
}
