import XCTest
@testable import UniversalTVRemote

final class CompositeDiscoveryServiceTests: XCTestCase {
    private final class MockSSDPScanner: SSDPScanning {
        private(set) var timeouts: [TimeInterval] = []
        var results: [DiscoveredDevice] = []

        func scan(timeout: TimeInterval) async -> [DiscoveredDevice] {
            timeouts.append(timeout)
            return results
        }
    }

    private final class MockBonjourScanner: BonjourScanning {
        private(set) var timeouts: [TimeInterval] = []
        var results: [DiscoveredDevice] = []

        func scan(timeout: TimeInterval) async -> [DiscoveredDevice] {
            timeouts.append(timeout)
            return results
        }
    }

    func testCompositeDiscoveryServiceUsesExpectedTimeouts() async {
        let ssdpScanner = MockSSDPScanner()
        let bonjourScanner = MockBonjourScanner()
        let service = CompositeDiscoveryService(ssdpScanner: ssdpScanner, bonjourScanner: bonjourScanner)

        _ = await service.scan()

        XCTAssertEqual(ssdpScanner.timeouts, [CompositeDiscoveryService.defaultSSDPTimeout])
        XCTAssertEqual(bonjourScanner.timeouts, [CompositeDiscoveryService.defaultBonjourTimeout])
#if DEBUG
        XCTAssertGreaterThanOrEqual(CompositeDiscoveryService.defaultBonjourTimeout, 8.0)
        XCTAssertLessThanOrEqual(CompositeDiscoveryService.defaultBonjourTimeout, 10.0)
        XCTAssertGreaterThanOrEqual(CompositeDiscoveryService.defaultSSDPTimeout, 6.0)
        XCTAssertLessThanOrEqual(CompositeDiscoveryService.defaultSSDPTimeout, 8.0)
#endif
    }

    func testCompositeDiscoveryServicePrefersSSDPWhenDuplicate() async {
        let ssdpScanner = MockSSDPScanner()
        let bonjourScanner = MockBonjourScanner()
        let service = CompositeDiscoveryService(ssdpScanner: ssdpScanner, bonjourScanner: bonjourScanner)

        let ssdpDevice = DiscoveredDevice(
            name: "LG webOS TV",
            ipAddress: "192.168.1.20",
            port: 3001,
            type: .lgWebOS,
            metadata: ["SOURCE": "SSDP"]
        )
        let bonjourDevice = DiscoveredDevice(
            name: "LG via Bonjour",
            ipAddress: "192.168.1.20",
            port: 3001,
            type: .lgWebOS,
            metadata: ["SOURCE": "BONJOUR"]
        )

        ssdpScanner.results = [ssdpDevice]
        bonjourScanner.results = [bonjourDevice]

        let devices = await service.scan()
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.metadata["SOURCE"], "SSDP")
    }
}
