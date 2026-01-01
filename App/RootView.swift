// File: App/RootView.swift

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView {
            OnboardingView()
                .tabItem { Label("Appareils", systemImage: "tv") }

            RemoteContainerView()
                .tabItem { Label("Télécommande", systemImage: "dot.radiowaves.left.and.right") }

            CastingContainerView()
                .tabItem { Label("Casting", systemImage: "airplayvideo") }

            SettingsView()
                .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
        .background(themeManager.selectedTheme.background)
    }
}
