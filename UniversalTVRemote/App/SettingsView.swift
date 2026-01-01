// File: App/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thèmes")) {
                    Picker("Thème", selection: Binding(
                        get: { themeManager.selectedTheme },
                        set: { themeManager.selectedTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue.capitalized).tag(theme)
                        }
                    }
                }

                Section(header: Text("Permissions")) {
                    Text("L'application utilise le réseau local pour découvrir les appareils (mDNS/SSDP) et le micro pour la dictée vocale.")
                }

                Section(header: Text("Limitations")) {
                    Text("Certaines marques nécessitent un pairing ou des APIs propriétaires. Les drivers stub sont prêts à être complétés.")
                }

                Section(header: Text("Diagnostics")) {
                    NavigationLink("Voir les diagnostics") {
                        DiagnosticsView()
                    }
                }
            }
            .navigationTitle("Réglages")
        }
    }
}
