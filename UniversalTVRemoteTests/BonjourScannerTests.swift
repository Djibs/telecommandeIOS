import XCTest
@testable import UniversalTVRemote

@MainActor
final class BonjourScannerTests: XCTestCase {
    private final class MockNetServiceBrowser: NetServiceBrowser {
        private(set) var searchCalls: [(type: String, domain: String)] = []
        private(set) var stopCount = 0

        override func searchForServices(ofType type: String, inDomain domainString: String) {
            searchCalls.append((type: type, domain: domainString))
        }

        override func stop() {
            stopCount += 1
        }
    }

    func testScanUsesOneBrowserPerServiceTypeAndStopsOnDidNotSearch() async {
        var createdBrowsers: [String: MockNetServiceBrowser] = [:]
        let scanner = BonjourScanner { type in
            let browser = MockNetServiceBrowser()
            createdBrowsers[type] = browser
            return browser
        }

        let scanTask = Task { @MainActor in
            await scanner.scan(timeout: 60)
        }

        await Task.yield()

        XCTAssertEqual(Set(createdBrowsers.keys), Set(["_roku._tcp.", "_googlecast._tcp."]))
        for (type, browser) in createdBrowsers {
            XCTAssertEqual(browser.searchCalls.count, 1, "searchForServices doit être appelé une seule fois pour \(type)")
            XCTAssertEqual(browser.searchCalls.first?.type, type)
            XCTAssertEqual(browser.searchCalls.first?.domain, "local.")
        }

        if let browser = createdBrowsers["_roku._tcp."] {
            scanner.netServiceBrowser(browser, didNotSearch: ["err": 1])
        } else {
            XCTFail("Browser attendu pour _roku._tcp. absent")
        }

        _ = await scanTask.value

        for (_, browser) in createdBrowsers {
            XCTAssertEqual(browser.stopCount, 1, "stop doit être appelé pour tous les browsers")
        }
    }
}
