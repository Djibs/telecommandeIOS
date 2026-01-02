// File: Tests/IPAddressValidatorTests.swift

import XCTest
@testable import UniversalTVRemote

final class IPAddressValidatorTests: XCTestCase {
    func testValidIPv4Addresses() {
        XCTAssertTrue(IPAddressValidator.isValidIPv4("192.168.0.1"))
        XCTAssertTrue(IPAddressValidator.isValidIPv4("10.0.0.255"))
        XCTAssertTrue(IPAddressValidator.isValidIPv4("0.0.0.0"))
    }

    func testInvalidIPv4Addresses() {
        XCTAssertFalse(IPAddressValidator.isValidIPv4(""))
        XCTAssertFalse(IPAddressValidator.isValidIPv4("192.168.1"))
        XCTAssertFalse(IPAddressValidator.isValidIPv4("192.168.1.256"))
        XCTAssertFalse(IPAddressValidator.isValidIPv4("192.168.1.-1"))
        XCTAssertFalse(IPAddressValidator.isValidIPv4("192.168.1.a"))
        XCTAssertFalse(IPAddressValidator.isValidIPv4("192.168.1."))
    }
}
