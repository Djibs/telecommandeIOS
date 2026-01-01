// File: Core/Logging/Logger.swift

import Foundation
import os.log

public enum AppLogger {
    private static let subsystem = "com.universalTVRemote"

    public static let discovery = Logger(subsystem: subsystem, category: "Discovery")
    public static let driver = Logger(subsystem: subsystem, category: "Driver")
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    public static let voice = Logger(subsystem: subsystem, category: "Voice")
}
