// File: Core/Discovery/DeviceDiscoveryViewModel.swift

import Foundation
import SwiftUI

@MainActor
public final class DeviceDiscoveryViewModel: ObservableObject {
    @Published public private(set) var devices: [DiscoveredDevice] = []
    @Published public private(set) var isScanning = false
    @Published public private(set) var error: RemoteError?

    private let discoveryService: DeviceDiscoveryService

    public init(discoveryService: DeviceDiscoveryService) {
        self.discoveryService = discoveryService
    }

    public func scan() async {
        isScanning = true
        error = nil
        let results = await discoveryService.scan()
        if results.isEmpty {
            error = .timeout
        }
        devices = results
        isScanning = false
    }
}
