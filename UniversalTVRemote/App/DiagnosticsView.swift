// File: App/DiagnosticsView.swift

import SwiftUI
import UIKit

struct DiagnosticsView: View {
    @AppStorage(AppSettingsKeys.verboseLogsEnabled) private var verboseLogsEnabled = false
    @AppStorage(AppSettingsKeys.lastLGDeviceName) private var lastLGDeviceName = ""
    @AppStorage(AppSettingsKeys.lastLGDeviceIP) private var lastLGDeviceIP = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private var iosVersion: String {
        UIDevice.current.systemVersion
    }

    private var deviceModel: String {
        UIDevice.current.model
    }

    private var lastLGDeviceLabel: String {
        guard !lastLGDeviceName.isEmpty || !lastLGDeviceIP.isEmpty else {
            return "Aucune TV LG sélectionnée"
        }
        if lastLGDeviceName.isEmpty {
            return lastLGDeviceIP
        }
        if lastLGDeviceIP.isEmpty {
            return lastLGDeviceName
        }
        return "\(lastLGDeviceName) • \(lastLGDeviceIP)"
    }

    var body: some View {
        Form {
            Section(header: Text("Logs")) {
                Toggle("Verbose logs", isOn: $verboseLogsEnabled)
            }

            Section(header: Text("Environnement")) {
                LabeledContent("Version app", value: appVersion)
                LabeledContent("iOS", value: iosVersion)
                LabeledContent("Modèle", value: deviceModel)
            }

            Section(header: Text("Dernier appareil LG")) {
                Text(lastLGDeviceLabel)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Diagnostics")
    }
}
