// File: Tests/VoiceCommandRouterTests.swift

import XCTest
@testable import UniversalTVRemote

final class VoiceCommandRouterTests: XCTestCase {
    func testVolumeUpParsing() {
        let router = VoiceCommandRouter()
        XCTAssertEqual(router.map(text: "Monte le son"), .volumeUp)
    }

    func testMuteParsing() {
        let router = VoiceCommandRouter()
        XCTAssertEqual(router.map(text: "Muet"), .mute)
    }

    func testHomeParsing() {
        let router = VoiceCommandRouter()
        XCTAssertEqual(router.map(text: "Accueil"), .home)
    }
}
