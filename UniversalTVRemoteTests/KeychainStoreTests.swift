// File: UniversalTVRemoteTests/KeychainStoreTests.swift

import XCTest
@testable import UniversalTVRemote

final class KeychainStoreTests: XCTestCase {
    func testSetAndGetValue() throws {
        let store = KeychainStore()
        let key = "test.lgwebos.\(UUID().uuidString)"
        let value = "client-key".data(using: .utf8)!

        defer {
            try? store.delete(key)
        }

        try store.set(value, forKey: key)
        let loaded = try store.get(key)

        XCTAssertEqual(loaded, value)
    }
}
