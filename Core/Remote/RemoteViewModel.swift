// File: Core/Remote/RemoteViewModel.swift

import Foundation
import SwiftUI

@MainActor
public final class RemoteViewModel: ObservableObject {
    @Published public private(set) var status: String = "Déconnecté"
    @Published public private(set) var errorMessage: String?
    @Published public var quickText: String = ""

    private let driver: TVDriver
    private let router: CommandRouting

    public init(driver: TVDriver) {
        self.driver = driver
        self.router = CommandRouter(driver: driver)
    }

    public func connect() async {
        status = "Connexion…"
        do {
            try await driver.connect()
            status = "Connecté"
        } catch {
            status = "Erreur"
            errorMessage = error.localizedDescription
        }
    }

    public func send(_ command: RemoteCommand) async {
        do {
            try await router.send(command: command)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func sendText() async {
        let text = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        do {
            try await router.sendText(text)
            quickText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func launch(_ app: LaunchableApp) async {
        do {
            try await router.launch(app: app)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
