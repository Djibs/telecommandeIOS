// File: App/AppState.swift

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var selectedDevice: DiscoveredDevice? {
        didSet {
            selectedDriver = selectedDevice.map { driverRegistry.driver(for: $0) }
        }
    }
    @Published var selectedDriver: TVDriver?

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
        selectedDriver
    }
}
