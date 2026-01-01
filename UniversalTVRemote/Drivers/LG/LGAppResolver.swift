// File: Drivers/LG/LGAppResolver.swift

import Foundation
import WebOSClient
import Combine

public enum LGAppResolverError: LocalizedError {
    case notReady
    case appNotFound
    case launchFailed

    public var errorDescription: String? {
        switch self {
        case .notReady:
            return "TV LG non prête pour le lancement d'applications."
        case .appNotFound:
            return "App non disponible sur cette TV."
        case .launchFailed:
            return "Échec du lancement de l'app sur la TV."
        }
    }
}

@MainActor
public protocol LGWebOSRequesting: LGWebOSControlling {
    func sendRequest(_ target: WebOSTarget) async throws -> WebOSResponse
    func send(_ target: WebOSTarget)
}

@MainActor
public final class LGAppResolver: ObservableObject {
    @Published public private(set) var availableApps: Set<StreamingApp> = []
    @Published public private(set) var isLoaded: Bool = false

    private let service: LGWebOSRequesting
    private let cache: LGAppCaching
    private let logger = AppLogger.lgWebOS

    private let titleMap: [StreamingApp: [String]] = [
        .netflix: ["Netflix"],
        .youtube: ["YouTube"],
        .primeVideo: ["Prime Video", "Amazon Prime Video", "Prime"],
        .disneyPlus: ["Disney+", "Disney Plus"],
        .appleTV: ["Apple TV", "Apple TV+"],
        .hulu: ["Hulu"]
    ]

    private let fallbackIds: [StreamingApp: [String]] = [
        .netflix: ["netflix"],
        .youtube: ["youtube.leanback.v4"],
        .primeVideo: ["amazon", "com.webos.app.amazon"],
        .disneyPlus: ["com.disney.disneyplus-prod"],
        .appleTV: ["com.apple.appletv"],
        .hulu: ["hulu"]
    ]

    public init(service: LGWebOSRequesting, cache: LGAppCaching = LGAppCache()) {
        self.service = service
        self.cache = cache
    }

    public func refreshInstalledApps() async throws -> [LGInstalledApp] {
        guard case .ready = service.state else {
            throw LGAppResolverError.notReady
        }
        logger.info("listApps démarré")
        let response = try await service.sendRequest(.listApps)
        let apps = response.payload?.applications ?? []
        let installedApps = apps.compactMap { app -> LGInstalledApp? in
            guard let id = app.id, let title = app.title else { return nil }
            return LGInstalledApp(id: id, title: title)
        }
        logger.info("listApps terminé: \(installedApps.count, privacy: .public) apps")
        updateAvailableApps(from: installedApps)
        isLoaded = true
        return installedApps
    }

    public func resolveAppId(for streamingApp: StreamingApp) async -> String? {
        let tvIdentifier = service.deviceIdentifier
        if let cached = cache.cachedAppId(for: streamingApp, tvIdentifier: tvIdentifier) {
            logger.info("Cache hit pour \(streamingApp.rawValue, privacy: .public)")
            return cached
        }
        logger.info("Cache miss pour \(streamingApp.rawValue, privacy: .public)")
        if let match = await resolveFromListApps(streamingApp: streamingApp) {
            cache.setCachedAppId(match, for: streamingApp, tvIdentifier: tvIdentifier)
            return match
        }
        logger.info("Aucun appId trouvé via listApps pour \(streamingApp.rawValue, privacy: .public)")
        return nil
    }

    public func launch(streamingApp: StreamingApp) async throws {
        guard case .ready = service.state else {
            throw LGAppResolverError.notReady
        }
        let tvIdentifier = service.deviceIdentifier
        if let cached = cache.cachedAppId(for: streamingApp, tvIdentifier: tvIdentifier) {
            logger.info("Lancement via cache \(streamingApp.rawValue, privacy: .public)")
            do {
                try await launchAppId(cached)
                availableApps.insert(streamingApp)
                return
            } catch {
                logger.warning("Cache invalide, relance listApps pour \(streamingApp.rawValue, privacy: .public)")
                cache.removeCachedAppId(for: streamingApp, tvIdentifier: tvIdentifier)
            }
        }

        if let resolved = await resolveFromListApps(streamingApp: streamingApp) {
            logger.info("AppId résolu \(resolved, privacy: .public) pour \(streamingApp.rawValue, privacy: .public)")
            cache.setCachedAppId(resolved, for: streamingApp, tvIdentifier: tvIdentifier)
            try await launchAppId(resolved)
            availableApps.insert(streamingApp)
            return
        }

        if let fallbackList = fallbackIds[streamingApp] {
            for fallback in fallbackList {
                logger.info("Fallback appId \(fallback, privacy: .public) pour \(streamingApp.rawValue, privacy: .public)")
                do {
                    try await launchAppId(fallback)
                    cache.setCachedAppId(fallback, for: streamingApp, tvIdentifier: tvIdentifier)
                    availableApps.insert(streamingApp)
                    return
                } catch {
                    continue
                }
            }
        }
        logger.error("App introuvable: \(streamingApp.rawValue, privacy: .public)")
        throw LGAppResolverError.appNotFound
    }

    private func resolveFromListApps(streamingApp: StreamingApp) async -> String? {
        do {
            let apps = try await refreshInstalledApps()
            let titles = titleMap[streamingApp, default: []].map { $0.lowercased() }
            if let match = apps.first(where: { app in
                let name = app.title.lowercased()
                return titles.contains(where: { name.contains($0.lowercased()) })
            }) {
                logger.info("Match titre \(match.title, privacy: .public) -> \(match.id, privacy: .public)")
                return match.id
            }
        } catch {
            logger.error("Erreur listApps: \(error.localizedDescription, privacy: .public)")
        }
        return nil
    }

    private func launchAppId(_ appId: String) async throws {
        let response = try await service.sendRequest(.launchApp(appId: appId))
        if response.payload?.returnValue == true {
            return
        }
        throw LGAppResolverError.launchFailed
    }

    private func updateAvailableApps(from installedApps: [LGInstalledApp]) {
        var available: Set<StreamingApp> = []
        for app in StreamingApp.allCases {
            let titles = titleMap[app, default: []].map { $0.lowercased() }
            let matched = installedApps.contains { installed in
                let title = installed.title.lowercased()
                return titles.contains(where: { title.contains($0.lowercased()) })
            }
            if matched {
                available.insert(app)
            }
        }
        availableApps = available
    }
}
