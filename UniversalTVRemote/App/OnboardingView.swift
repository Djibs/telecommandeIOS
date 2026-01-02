// File: App/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var discoveryViewModel: DeviceDiscoveryViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingManualEntry = false
    @State private var manualIPAddress = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Ajouter un appareil")
                    .font(.title2.bold())

                if discoveryViewModel.isScanning {
                    ProgressView("Scan du réseau local…")
                }

                Button(action: {
                    Task { await discoveryViewModel.scan() }
                }) {
                    Label("Scanner le réseau", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    showingManualEntry = true
                }) {
                    Label("Entrer l’IP manuellement", systemImage: "pencil")
                }
                .buttonStyle(.bordered)

                if let error = discoveryViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }

                List(discoveryViewModel.devices) { device in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.headline)
                            Text("\(device.type.rawValue.uppercased()) • \(device.ipAddress)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if appState.selectedDevice == device {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(themeManager.selectedTheme.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.selectedDevice = device
                    }
                }
                .listStyle(.insetGrouped)
            }
            .padding()
            .navigationTitle("Découverte")
        }
        .sheet(isPresented: $showingManualEntry) {
            NavigationView {
                let trimmedIP = manualIPAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                let isValidIP = IPAddressValidator.isValidIPv4(trimmedIP)
                Form {
                    Section(header: Text("LG webOS")) {
                        TextField("Adresse IP", text: $manualIPAddress)
                            .keyboardType(.numbersAndPunctuation)
                        if !manualIPAddress.isEmpty && !isValidIP {
                            Text("Format IP invalide (ex: 192.168.1.50)")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Connexion LG")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { showingManualEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Connecter") {
                            guard isValidIP else { return }
                            let device = DiscoveredDevice(
                                name: "LG webOS (manuel)",
                                ipAddress: trimmedIP,
                                port: 3001,
                                type: .lgWebOS,
                                metadata: ["SOURCE": "MANUAL"]
                            )
                            discoveryViewModel.addManualDevice(device)
                            showingManualEntry = false
                            manualIPAddress = ""
                        }
                        .disabled(!isValidIP)
                    }
                }
            }
        }
    }
}
