// File: Tests/SSDPParsingTests.swift

import XCTest
@testable import UniversalTVRemote

final class SSDPParsingTests: XCTestCase {
    func testParseSSDPHeaders() {
        let response = "HTTP/1.1 200 OK\r\nST: roku:ecp\r\nLOCATION: http://192.168.1.2:8060\r\nSERVER: Roku/1.0\r\n\r\n"
        let data = Data(response.utf8)
        let scanner = SSDPScanner()
        let headers = scanner.parseSSDPResponse(data)
        XCTAssertEqual(headers["ST"], "roku:ecp")
        XCTAssertEqual(headers["LOCATION"], "http://192.168.1.2:8060")
    }

    func testParseContainsLocation() {
        let response = "HTTP/1.1 200 OK\r\nST: roku:ecp\r\nLOCATION: http://192.168.1.2:8060\r\nSERVER: Roku/1.0\r\n\r\n"
        let data = Data(response.utf8)
        let scanner = SSDPScanner()
        let headers = scanner.parseSSDPResponse(data)
        XCTAssertEqual(headers["LOCATION"], "http://192.168.1.2:8060")
    }
}
