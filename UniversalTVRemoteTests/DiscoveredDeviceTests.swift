// File: Tests/DiscoveredDeviceTests.swift

import XCTest
@testable import UniversalTVRemote

final class DiscoveredDeviceTests: XCTestCase {
    func testDiscoveredDeviceEqualityUsesIPAddressAndType() {
        let first = DiscoveredDevice(
            name: "LG webOS TV",
            ipAddress: "192.168.1.10",
            port: 3001,
            type: .lgWebOS,
            metadata: ["SOURCE": "SSDP"]
        )
        let second = DiscoveredDevice(
            name: "LG webOS TV (autre nom)",
            ipAddress: "192.168.1.10",
            port: 3001,
            type: .lgWebOS,
            metadata: ["SOURCE": "BONJOUR"]
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(Set([first, second]).count, 1)
    }

    func testDiscoveredDeviceInequalityWhenTypeDiffers() {
        let first = DiscoveredDevice(
            name: "LG webOS TV",
            ipAddress: "192.168.1.10",
            type: .lgWebOS
        )
        let second = DiscoveredDevice(
            name: "DLNA",
            ipAddress: "192.168.1.10",
            type: .dlnaGeneric
        )

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(Set([first, second]).count, 2)
    }
}
