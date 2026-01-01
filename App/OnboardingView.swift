// File: App/OnboardingView.swift

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

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
    }
}
