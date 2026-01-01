// File: App/AppState.swift

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedDevice: DiscoveredDevice?

    let discoveryViewModel: DeviceDiscoveryViewModel
    let driverRegistry: DriverRegistry

    init(
        discoveryService: DeviceDiscoveryService = CompositeDiscoveryService(),
        driverRegistry: DriverRegistry = DefaultDriverRegistry()
    ) {
        self.discoveryViewModel = DeviceDiscoveryViewModel(discoveryService: discoveryService)
        self.driverRegistry = driverRegistry
    }

    func driverForSelectedDevice() -> TVDriver? {
        guard let selectedDevice else { return nil }
        return driverRegistry.driver(for: selectedDevice)
    }
}
