import XCTest
@testable import UniversalTVRemote

final class CompositeDiscoveryServiceTests: XCTestCase {
    private final class MockSSDPScanner: SSDPScanning {
        private(set) var timeouts: [TimeInterval] = []

        func scan(timeout: TimeInterval) async -> [DiscoveredDevice] {
            timeouts.append(timeout)
            return []
        }
    }

    private final class MockBonjourScanner: BonjourScanning {
        private(set) var timeouts: [TimeInterval] = []

        func scan(timeout: TimeInterval) async -> [DiscoveredDevice] {
            timeouts.append(timeout)
            return []
        }
    }

    func testCompositeDiscoveryServiceUsesExpectedTimeouts() async {
        let ssdpScanner = MockSSDPScanner()
        let bonjourScanner = MockBonjourScanner()
        let service = CompositeDiscoveryService(ssdpScanner: ssdpScanner, bonjourScanner: bonjourScanner)

        _ = await service.scan()

        XCTAssertEqual(ssdpScanner.timeouts, [3.0])
        XCTAssertEqual(bonjourScanner.timeouts, [CompositeDiscoveryService.defaultBonjourTimeout])
#if DEBUG
        XCTAssertGreaterThanOrEqual(CompositeDiscoveryService.defaultBonjourTimeout, 8.0)
        XCTAssertLessThanOrEqual(CompositeDiscoveryService.defaultBonjourTimeout, 10.0)
#endif
    }
}
