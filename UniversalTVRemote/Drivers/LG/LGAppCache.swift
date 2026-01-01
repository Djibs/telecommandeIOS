// File: Drivers/LG/LGAppCache.swift

import Foundation

public protocol LGAppCaching {
    func cachedAppId(for app: StreamingApp, tvIdentifier: String) -> String?
    func setCachedAppId(_ appId: String, for app: StreamingApp, tvIdentifier: String)
    func removeCachedAppId(for app: StreamingApp, tvIdentifier: String)
    func cachedMapping(tvIdentifier: String) -> [StreamingApp: String]
}

public final class LGAppCache: LGAppCaching {
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func cachedAppId(for app: StreamingApp, tvIdentifier: String) -> String? {
        cachedMapping(tvIdentifier: tvIdentifier)[app]
    }

    public func setCachedAppId(_ appId: String, for app: StreamingApp, tvIdentifier: String) {
        var mapping = cachedMapping(tvIdentifier: tvIdentifier)
        mapping[app] = appId
        save(mapping: mapping, tvIdentifier: tvIdentifier)
    }

    public func removeCachedAppId(for app: StreamingApp, tvIdentifier: String) {
        var mapping = cachedMapping(tvIdentifier: tvIdentifier)
        mapping.removeValue(forKey: app)
        save(mapping: mapping, tvIdentifier: tvIdentifier)
    }

    public func cachedMapping(tvIdentifier: String) -> [StreamingApp: String] {
        let key = cacheKey(for: tvIdentifier)
        guard let data = userDefaults.data(forKey: key) else { return [:] }
        do {
            let rawMapping = try decoder.decode([String: String].self, from: data)
            return rawMapping.reduce(into: [:]) { result, entry in
                if let app = StreamingApp(rawValue: entry.key) {
                    result[app] = entry.value
                }
            }
        } catch {
            return [:]
        }
    }

    private func save(mapping: [StreamingApp: String], tvIdentifier: String) {
        let key = cacheKey(for: tvIdentifier)
        let rawMapping = Dictionary(uniqueKeysWithValues: mapping.map { ($0.key.rawValue, $0.value) })
        if let data = try? encoder.encode(rawMapping) {
            userDefaults.set(data, forKey: key)
        }
    }

    private func cacheKey(for tvIdentifier: String) -> String {
        "lg_app_cache_\(tvIdentifier)"
    }
}
