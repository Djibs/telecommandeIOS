// File: Core/Logging/AppLogger.swift

import Foundation
import os

public enum LogCategory: String {
    case discovery
    case lgWebOS
    case driver
    case casting
    case voice
    case ui
}

public struct AppLogger {
    public static let verboseLogsEnabledKey = "verboseLogsEnabled"

    public static var userDefaults: UserDefaults = .standard

    public static let subsystem: String = Bundle.main.bundleIdentifier ?? "UniversalTVRemote"

    public static let discovery = Logger(subsystem: subsystem, category: LogCategory.discovery.rawValue)
    public static let lgWebOS = Logger(subsystem: subsystem, category: LogCategory.lgWebOS.rawValue)
    public static let driver = Logger(subsystem: subsystem, category: LogCategory.driver.rawValue)
    public static let casting = Logger(subsystem: subsystem, category: LogCategory.casting.rawValue)
    public static let voice = Logger(subsystem: subsystem, category: LogCategory.voice.rawValue)
    public static let ui = Logger(subsystem: subsystem, category: LogCategory.ui.rawValue)

    public static var isVerboseLoggingEnabled: Bool {
        userDefaults.bool(forKey: verboseLogsEnabledKey)
    }

    public static func debugIfVerbose(_ message: String, logger: Logger) {
        guard isVerboseLoggingEnabled else { return }
        logger.debug("\(message, privacy: .public)")
    }

    public static func truncate(_ value: String, maxLength: Int = 64) -> String {
        guard value.count > maxLength else { return value }
        return "\(value.prefix(maxLength))…"
    }
}
