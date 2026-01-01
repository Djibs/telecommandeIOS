// File: Core/Remote/ThemeManager.swift

import SwiftUI

public enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case neon

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .neon: return .dark
        }
    }

    public var accentColor: Color {
        switch self {
        case .light: return .blue
        case .dark: return .orange
        case .neon: return .pink
        }
    }

    public var background: LinearGradient {
        switch self {
        case .light:
            return LinearGradient(colors: [Color.white, Color(white: 0.95)], startPoint: .top, endPoint: .bottom)
        case .dark:
            return LinearGradient(colors: [Color.black, Color(white: 0.2)], startPoint: .top, endPoint: .bottom)
        case .neon:
            return LinearGradient(colors: [Color.black, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

public final class ThemeManager: ObservableObject {
    @AppStorage("selectedTheme") public var selectedThemeRawValue: String = AppTheme.dark.rawValue

    public var selectedTheme: AppTheme {
        get { AppTheme(rawValue: selectedThemeRawValue) ?? .dark }
        set { selectedThemeRawValue = newValue.rawValue }
    }
}
