// File: App/LGPairingView.swift

import SwiftUI
import WebOSClient

struct LGPairingView: View {
    @ObservedObject var service: LGWebOSService
    @State private var pinCode: String = ""
    @State private var pairingType: WebOSPairingType = .prompt

    var body: some View {
        VStack(spacing: 16) {
            Text("Association LG webOS")
                .font(.title2.bold())

            Picker("Méthode", selection: $pairingType) {
                Text("Validation sur la TV").tag(WebOSPairingType.prompt)
                Text("Code PIN").tag(WebOSPairingType.pin)
            }
            .pickerStyle(.segmented)

            statusView

            if case .awaitingPin = service.state {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saisir le PIN affiché sur la TV")
                        .font(.headline)
                    TextField("PIN", text: $pinCode)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button("Valider") {
                        service.setPin(pinCode)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Button("Relancer l'association") {
                Task { await service.restartPairing(pairingType: pairingType) }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .task {
            await connectIfNeeded()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch service.state {
        case .disconnected:
            Text("Déconnecté")
                .foregroundColor(.secondary)
        case .connecting:
            ProgressView("Connexion…")
        case .awaitingPrompt:
            Text("En attente d’acceptation sur la TV")
                .foregroundColor(.secondary)
        case .awaitingPin:
            Text("Saisie du PIN requise")
                .foregroundColor(.secondary)
        case .registering:
            ProgressView("Association en cours…")
        case .ready:
            Text("Connecté")
                .foregroundColor(.green)
        case .error(let message):
            Text(message)
                .foregroundColor(.red)
        }
    }

    private func connectIfNeeded() async {
        do {
            try await service.ensureReady(pairingType: pairingType)
        } catch {
            // L'erreur est exposée via l'état.
        }
    }
}

struct LGPairingContainerView: View {
    let driver: LGWebOSDriver
    @ObservedObject var service: LGWebOSService

    init(driver: LGWebOSDriver) {
        self.driver = driver
        self.service = driver.service ?? LGWebOSService(device: driver.device)
    }

    var body: some View {
        if service.hasStoredClientKey || service.state == .ready {
            RemoteView(viewModel: RemoteViewModel(driver: driver))
        } else {
            LGPairingView(service: service)
        }
    }
}
