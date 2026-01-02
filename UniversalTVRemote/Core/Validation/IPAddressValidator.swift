// File: Core/Validation/IPAddressValidator.swift

import Foundation

public enum IPAddressValidator {
    public static func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        for part in parts {
            guard !part.isEmpty, part.count <= 3, let number = Int(part), (0...255).contains(number) else {
                return false
            }
        }
        return true
    }
}
