// File: App/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingManualEntry = false
    @State private var manualIPAddress = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Ajouter un appareil")
                    .font(.title2.bold())

                if appState.discoveryViewModel.isScanning {
                    ProgressView("Scan du réseau local…")
                }

                Button(action: {
                    Task { await appState.discoveryViewModel.scan() }
                }) {
                    Label("Scanner le réseau", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    showingManualEntry = true
                }) {
                    Label("Saisie IP manuelle", systemImage: "pencil")
                }
                .buttonStyle(.bordered)

                if let error = appState.discoveryViewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }

                List(appState.discoveryViewModel.devices) { device in
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
                Form {
                    Section(header: Text("LG webOS")) {
                        TextField("Adresse IP", text: $manualIPAddress)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
                .navigationTitle("Ajout manuel")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { showingManualEntry = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ajouter") {
                            let ip = manualIPAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !ip.isEmpty else { return }
                            let device = DiscoveredDevice(
                                name: "LG webOS TV \(ip)",
                                ipAddress: ip,
                                type: .lgWebOS
                            )
                            appState.discoveryViewModel.addManualDevice(device)
                            showingManualEntry = false
                            manualIPAddress = ""
                        }
                    }
                }
            }
        }
    }
}
