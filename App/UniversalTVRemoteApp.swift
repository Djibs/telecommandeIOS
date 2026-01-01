// File: App/UniversalTVRemoteApp.swift

import SwiftUI

@main
struct UniversalTVRemoteApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .accentColor(themeManager.selectedTheme.accentColor)
        }
    }
}
