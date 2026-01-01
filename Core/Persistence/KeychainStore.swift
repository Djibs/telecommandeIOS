// File: Core/Persistence/KeychainStore.swift

import Foundation
import Security

public protocol KeychainStoring {
    func set(_ value: Data, forKey key: String) throws
    func get(_ key: String) throws -> Data?
    func delete(_ key: String) throws
}

public final class KeychainStore: KeychainStoring {
    public init() {}

    public func set(_ value: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw RemoteError.network("Keychain set error: \(status)")
        }
    }

    public func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw RemoteError.network("Keychain get error: \(status)")
        }
        return item as? Data
    }

    public func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw RemoteError.network("Keychain delete error: \(status)")
        }
    }
}
