// File: Tests/AppLoggerTests.swift

import XCTest
@testable import UniversalTVRemote

final class AppLoggerTests: XCTestCase {
    private let suiteName = "AppLoggerTests"
    private var originalDefaults: UserDefaults?

    override func setUp() {
        super.setUp()
        originalDefaults = AppLogger.userDefaults
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        AppLogger.userDefaults = defaults
    }

    override func tearDown() {
        if let originalDefaults {
            AppLogger.userDefaults = originalDefaults
        }
        super.tearDown()
    }

    func testVerboseFlagReflectsUserDefaults() {
        AppLogger.userDefaults.set(true, forKey: AppSettingsKeys.verboseLogsEnabled)
        XCTAssertTrue(AppLogger.isVerboseLoggingEnabled)

        AppLogger.userDefaults.set(false, forKey: AppSettingsKeys.verboseLogsEnabled)
        XCTAssertFalse(AppLogger.isVerboseLoggingEnabled)
    }

    func testTruncateAddsEllipsisWhenNeeded() {
        XCTAssertEqual(AppLogger.truncate("abcdef", maxLength: 10), "abcdef")
        XCTAssertEqual(AppLogger.truncate("0123456789ABC", maxLength: 10), "0123456789…")
    }
}
