// File: Core/Models/Models.swift
// Modèles principaux pour Universal TV Remote

import Foundation

public enum DeviceType: String, Codable, CaseIterable {
    case roku
    case chromecast
    case lgWebOS
    case samsungTizen
    case sonyBravia
    case dlnaGeneric
    case unknown
}

public struct DiscoveredDevice: Identifiable, Hashable, Codable {
    public let id: UUID
    public let name: String
    public let ipAddress: String
    public let port: Int?
    public let type: DeviceType
    public let metadata: [String: String]

    public init(
        id: UUID = UUID(),
        name: String,
        ipAddress: String,
        port: Int? = nil,
        type: DeviceType,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.type = type
        self.metadata = metadata
    }

    public static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        lhs.ipAddress == rhs.ipAddress && lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ipAddress)
        hasher.combine(type)
    }
}

public enum Capability: String, CaseIterable, Hashable, Codable {
    case power
    case volume
    case mute
    case navigation
    case playback
    case channel
    case textInput
    case launcher
    case casting
    case touchpad
    case voice
}

public enum RemoteCommand: Equatable {
    case power
    case digit(Int)
    case home
    case back
    case ok
    case up
    case down
    case left
    case right
    case menu
    case volumeUp
    case volumeDown
    case mute
    case playPause
    case play
    case pause
    case fastForward
    case rewind
    case channelUp
    case channelDown
    case settings
    case input
    case list
    case adSap
}

public enum LaunchableApp: String, CaseIterable, Codable {
    case netflix
    case primeVideo
    case youtube
    case disneyPlus
    case plex
}

public enum MediaType: String, Codable {
    case photo
    case video
}

public struct DeviceIdentity: Hashable, Codable {
    public let name: String
    public let model: String?
    public let manufacturer: String?

    public init(name: String, model: String? = nil, manufacturer: String? = nil) {
        self.name = name
        self.model = model
        self.manufacturer = manufacturer
    }
}

public enum RemoteError: Error, LocalizedError {
    case unsupported
    case connectionFailed
    case pairingRequired
    case invalidResponse
    case timeout
    case network(String)

    public var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Fonction non supportée par l'appareil."
        case .connectionFailed:
            return "Connexion impossible avec l'appareil."
        case .pairingRequired:
            return "Pairing requis pour cet appareil."
        case .invalidResponse:
            return "Réponse invalide de l'appareil."
        case .timeout:
            return "Délai d'attente dépassé."
        case .network(let message):
            return "Erreur réseau: \(message)"
        }
    }
}
