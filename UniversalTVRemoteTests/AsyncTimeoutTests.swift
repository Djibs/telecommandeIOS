import XCTest
@testable import UniversalTVRemote

final class AsyncTimeoutTests: XCTestCase {
    func testWithTimeoutReturnsValueBeforeTimeout() async throws {
        let result = try await withTimeout(0.2) {
            try await Task.sleep(nanoseconds: 10_000_000)
            return "ok"
        }

        XCTAssertEqual(result, "ok")
    }

    func testWithTimeoutReturnsNilAfterTimeout() async throws {
        let result = try await withTimeout(0.05) {
            try await Task.sleep(nanoseconds: 200_000_000)
            return "trop tard"
        }

        XCTAssertNil(result)
    }
}
