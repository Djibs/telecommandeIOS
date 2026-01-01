// File: Drivers/LG/LGInstalledApp.swift

import Foundation

public struct LGInstalledApp: Equatable, Hashable, Codable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}
