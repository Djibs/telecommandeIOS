// File: Core/Utils/AsyncTimeout.swift

import Foundation

public func withTimeout<T>(
    _ timeout: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T? {
    guard timeout > 0 else { return nil }

    return try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            return nil
        }

        let result = try await group.next() ?? nil
        group.cancelAll()
        return result
    }
}
