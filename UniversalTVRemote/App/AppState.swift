// File: App/AppState.swift

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedDevice: DiscoveredDevice? {
        didSet {
            selectedDriver = selectedDevice.map { driverRegistry.driver(for: $0) }
            persistLastLGDevice(from: selectedDevice)
        }
    }
    @Published var selectedDriver: TVDriver?

    let discoveryViewModel: DeviceDiscoveryViewModel
    let driverRegistry: DriverRegistry
    private let userDefaults: UserDefaults

    init(
            discoveryService: DeviceDiscoveryService? = nil,
            driverRegistry: DriverRegistry? = nil,
            userDefaults: UserDefaults = .standard
        ) {
            let service = discoveryService ?? CompositeDiscoveryService.makeDefault()
            let registry = driverRegistry ?? DefaultDriverRegistry()

            self.discoveryViewModel = DeviceDiscoveryViewModel(discoveryService: service)
            self.driverRegistry = registry
            self.userDefaults = userDefaults
        }

    func driverForSelectedDevice() -> TVDriver? {
        selectedDriver
    }

    private func persistLastLGDevice(from device: DiscoveredDevice?) {
        guard let device, device.type == .lgWebOS else { return }
        userDefaults.set(device.name, forKey: AppSettingsKeys.lastLGDeviceName)
        userDefaults.set(device.ipAddress, forKey: AppSettingsKeys.lastLGDeviceIP)
    }
}
