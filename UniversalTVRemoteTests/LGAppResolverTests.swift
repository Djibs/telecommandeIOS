// File: UniversalTVRemoteTests/LGAppResolverTests.swift

import XCTest
import WebOSClient
@testable import UniversalTVRemote

final class LGAppResolverTests: XCTestCase {
    func testLaunchUsesCacheWhenValid() async throws {
        let service = FakeLGRequestService()
        let cache = InMemoryLGAppCache(mapping: [.netflix: "cached.netflix"])
        let resolver = LGAppResolver(service: service, cache: cache)

        try await resolver.launch(streamingApp: .netflix)

        XCTAssertEqual(service.launchRequests, ["cached.netflix"])
        XCTAssertTrue(service.listAppsRequested.isEmpty)
    }

    func testLaunchRefreshesWhenCacheInvalid() async throws {
        let service = FakeLGRequestService()
        service.launchResults = [
            "cached.netflix": false,
            "netflix.app": true
        ]
        service.installedApps = [LGInstalledApp(id: "netflix.app", title: "Netflix")]
        let cache = InMemoryLGAppCache(mapping: [.netflix: "cached.netflix"])
        let resolver = LGAppResolver(service: service, cache: cache)

        try await resolver.launch(streamingApp: .netflix)

        XCTAssertEqual(service.listAppsRequested.count, 1)
        XCTAssertEqual(service.launchRequests, ["cached.netflix", "netflix.app"])
        XCTAssertEqual(cache.cachedAppId(for: .netflix, tvIdentifier: service.deviceIdentifier), "netflix.app")
    }

    func testLaunchFallsBackWhenNotFoundInListApps() async throws {
        let service = FakeLGRequestService()
        service.launchResults = ["youtube.leanback.v4": true]
        service.installedApps = []
        let cache = InMemoryLGAppCache()
        let resolver = LGAppResolver(service: service, cache: cache)

        try await resolver.launch(streamingApp: .youtube)

        XCTAssertEqual(service.listAppsRequested.count, 1)
        XCTAssertEqual(service.launchRequests, ["youtube.leanback.v4"])
        XCTAssertEqual(cache.cachedAppId(for: .youtube, tvIdentifier: service.deviceIdentifier), "youtube.leanback.v4")
    }

    func testLaunchThrowsWhenNothingAvailable() async {
        let service = FakeLGRequestService()
        service.installedApps = []
        let cache = InMemoryLGAppCache()
        let resolver = LGAppResolver(service: service, cache: cache)

        do {
            try await resolver.launch(streamingApp: .appleTV)
            XCTFail("Le lancement doit échouer quand aucune app n'est disponible")
        } catch {
            XCTAssertTrue(error is LGAppResolverError)
        }
    }
}

private final class FakeLGRequestService: LGWebOSRequesting {
    var state: LGWebOSConnectionState = .ready
    var hasStoredClientKey: Bool = true
    var deviceIdentifier: String = "lgwebos.test"
    var installedApps: [LGInstalledApp] = []
    var launchResults: [String: Bool] = [:]
    var launchRequests: [String] = []
    var listAppsRequested: [Bool] = []

    func ensureReady(pairingType: WebOSPairingType?) async throws {}
    func disconnect() {}
    func restartPairing(pairingType: WebOSPairingType) async {}
    func setPin(_ pin: String) {}

    func sendRequest(_ target: WebOSTarget) async throws -> WebOSResponse {
        switch target {
        case .listApps:
            listAppsRequested.append(true)
            let apps = installedApps.map {
                WebOSResponseApplication(
                    id: $0.id,
                    title: $0.title,
                    icon: nil,
                    folderPath: nil,
                    version: nil,
                    systemApp: nil,
                    visible: nil,
                    vendor: nil,
                    type: nil
                )
            }
            return makeResponse(returnValue: true, applications: apps)
        case .launchApp(let appId, _, _):
            launchRequests.append(appId)
            let result = launchResults[appId] ?? false
            return makeResponse(returnValue: result, applications: nil)
        default:
            return makeResponse(returnValue: true, applications: nil)
        }
    }

    func send(_ target: WebOSTarget) {}

    private func makeResponse(returnValue: Bool, applications: [WebOSResponseApplication]?) -> WebOSResponse {
        WebOSResponse(
            type: nil,
            id: UUID().uuidString,
            error: nil,
            payload: WebOSResponsePayload(
                errorText: nil,
                pairingType: nil,
                returnValue: returnValue,
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
                applications: applications,
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

private final class InMemoryLGAppCache: LGAppCaching {
    private var mapping: [StreamingApp: String]

    init(mapping: [StreamingApp: String] = [:]) {
        self.mapping = mapping
    }

    func cachedAppId(for app: StreamingApp, tvIdentifier: String) -> String? {
        mapping[app]
    }

    func setCachedAppId(_ appId: String, for app: StreamingApp, tvIdentifier: String) {
        mapping[app] = appId
    }

    func removeCachedAppId(for app: StreamingApp, tvIdentifier: String) {
        mapping.removeValue(forKey: app)
    }

    func cachedMapping(tvIdentifier: String) -> [StreamingApp: String] {
        mapping
    }
}
