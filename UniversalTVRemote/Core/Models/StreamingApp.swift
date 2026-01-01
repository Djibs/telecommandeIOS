// File: Core/Models/StreamingApp.swift

import Foundation

public enum StreamingApp: String, CaseIterable, Codable, Hashable, Identifiable {
    case netflix
    case youtube
    case primeVideo
    case disneyPlus
    case appleTV
    case hulu

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .netflix:
            return "Netflix"
        case .youtube:
            return "YouTube"
        case .primeVideo:
            return "Prime Video"
        case .disneyPlus:
            return "Disney+"
        case .appleTV:
            return "Apple TV"
        case .hulu:
            return "Hulu"
        }
    }
}
