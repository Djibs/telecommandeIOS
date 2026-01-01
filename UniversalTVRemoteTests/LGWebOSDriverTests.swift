// File: UniversalTVRemoteTests/LGWebOSDriverTests.swift

import XCTest
import WebOSClient
@testable import UniversalTVRemote

final class LGWebOSDriverTests: XCTestCase {
    func testSendVolumeUpMapsToWebOSTarget() async throws {
        let controller = FakeLGWebOSController()
        let driver = LGWebOSDriver(device: makeDevice(), controller: controller)

        try await driver.send(command: .volumeUp)

        XCTAssertEqual(controller.sentTargets.count, 1)
        if case .volumeUp = controller.sentTargets.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("volumeUp doit être mappé sur WebOSTarget.volumeUp")
        }
    }

    func testSendNavigationMapsToWebOSKey() async throws {
        let controller = FakeLGWebOSController()
        let driver = LGWebOSDriver(device: makeDevice(), controller: controller)

        try await driver.send(command: .left)

        XCTAssertEqual(controller.sentKeys.count, 1)
        if case .left = controller.sentKeys.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("left doit être mappé sur WebOSKeyTarget.left")
        }
    }

    func testSendTextMapsToInsertTextAndEnter() async throws {
        let controller = FakeLGWebOSController()
        let driver = LGWebOSDriver(device: makeDevice(), controller: controller)

        try await driver.sendText("Bonjour")

        XCTAssertEqual(controller.sentTargets.count, 2)
        guard controller.sentTargets.count == 2 else { return }
        if case .insertText(let text, let replace) = controller.sentTargets[0] {
            XCTAssertEqual(text, "Bonjour")
            XCTAssertTrue(replace)
        } else {
            XCTFail("Le premier target doit être insertText")
        }
        if case .sendEnterKey = controller.sentTargets[1] {
            XCTAssertTrue(true)
        } else {
            XCTFail("Le second target doit être sendEnterKey")
        }
    }

    private func makeDevice() -> DiscoveredDevice {
        DiscoveredDevice(name: "LG webOS", ipAddress: "192.168.1.2", type: .lgWebOS)
    }
}

private final class FakeLGWebOSController: LGWebOSControlling, LGWebOSRequesting {
    var state: LGWebOSConnectionState = .ready
    var hasStoredClientKey: Bool = true
    var deviceIdentifier: String = "lgwebos.test"
    var sentTargets: [WebOSTarget] = []
    var sentKeys: [WebOSKeyTarget] = []

    func ensureReady(pairingType: WebOSPairingType?) async throws {}
    func disconnect() {}
    func restartPairing(pairingType: WebOSPairingType) async {}
    func setPin(_ pin: String) {}

    func send(_ target: WebOSTarget) {
        sentTargets.append(target)
    }

    func sendKey(_ key: WebOSKeyTarget) {
        sentKeys.append(key)
    }

    func sendRequest(_ target: WebOSTarget) async throws -> WebOSResponse {
        sentTargets.append(target)
        return WebOSResponse(
            type: nil,
            id: UUID().uuidString,
            error: nil,
            payload: WebOSResponsePayload(
                errorText: nil,
                pairingType: nil,
                returnValue: true,
                clientKey: nil,
                toastId: nil,
                callerId: nil,
                volume: nil,
                soundOutput: nil,
                volumeStatus: nil,
                muteStatus: nil,
                method: nil,
                state: nil,
                processing: nil,
                onOff: nil,
                reason: nil,
                productName: nil,
                modelName: nil,
                swType: nil,
                majorVer: nil,
                minorVer: nil,
                country: nil,
                countryGroup: nil,
                deviceId: nil,
                authFlag: nil,
                ignoreDisable: nil,
                ecoInfo: nil,
                configKey: nil,
                languageCode: nil,
                subscribed: nil,
                applications: nil,
                appId: nil,
                processId: nil,
                windowId: nil,
                id: nil,
                sessionId: nil,
                socketPath: nil,
                focusChanged: nil,
                currentWidget: nil,
                devices: nil,
                foregroundAppInfo: nil
            )
        )
    }
}
