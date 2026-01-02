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

    func testParseHandlesLowercaseHeaders() {
        let response = "HTTP/1.1 200 OK\r\nst: urn:lge-com:service:webos-second-screen:1\r\nlocation: http://192.168.1.50:3000\r\ncache-control: max-age=1800\r\n\r\n"
        let data = Data(response.utf8)
        let scanner = SSDPScanner()
        let headers = scanner.parseSSDPResponse(data)
        XCTAssertEqual(headers["ST"], "urn:lge-com:service:webos-second-screen:1")
        XCTAssertEqual(headers["LOCATION"], "http://192.168.1.50:3000")
        XCTAssertEqual(headers["CACHE-CONTROL"], "max-age=1800")
    }

    func testParseTrimsHeaderWhitespace() {
        let response = "HTTP/1.1 200 OK\r\nST:  roku:ecp  \r\nLOCATION:   http://192.168.1.2:8060 \r\n\r\n"
        let data = Data(response.utf8)
        let scanner = SSDPScanner()
        let headers = scanner.parseSSDPResponse(data)
        XCTAssertEqual(headers["ST"], "roku:ecp")
        XCTAssertEqual(headers["LOCATION"], "http://192.168.1.2:8060")
    }
}
