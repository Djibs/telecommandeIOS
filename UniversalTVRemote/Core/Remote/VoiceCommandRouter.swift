// File: Core/Remote/VoiceCommandRouter.swift

import Foundation

public struct VoiceCommandRouter {
    public init() {}

    public func map(text: String) -> RemoteCommand? {
        let normalized = text.lowercased()
        if normalized.contains("monte") || normalized.contains("augmente") {
            return .volumeUp
        }
        if normalized.contains("baisse") || normalized.contains("diminue") {
            return .volumeDown
        }
        if normalized.contains("muet") || normalized.contains("mute") {
            return .mute
        }
        if normalized.contains("chaîne suivante") || normalized.contains("chaine suivante") || normalized.contains("suivante") {
            return .channelUp
        }
        if normalized.contains("chaîne précédente") || normalized.contains("chaine précédente") || normalized.contains("précédente") {
            return .channelDown
        }
        if normalized.contains("accueil") || normalized.contains("home") {
            return .home
        }
        if normalized.contains("retour") || normalized.contains("back") {
            return .back
        }
        if normalized.contains("menu") {
            return .menu
        }
        if normalized.contains("lecture") || normalized.contains("play") {
            return .play
        }
        if normalized.contains("pause") {
            return .pause
        }
        return nil
    }
}
