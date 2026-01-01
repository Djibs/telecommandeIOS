// File: Core/Discovery/DeviceDiscoveryService.swift

import Foundation

public protocol DeviceDiscoveryService {
    func scan() async -> [DiscoveredDevice]
}

public final class CompositeDiscoveryService: DeviceDiscoveryService {
    private let ssdpScanner: SSDPScanning
    private let bonjourScanner: BonjourScanning

    public init(ssdpScanner: SSDPScanning = SSDPScanner(), bonjourScanner: BonjourScanning = BonjourScanner()) {
        self.ssdpScanner = ssdpScanner
        self.bonjourScanner = bonjourScanner
    }

    public func scan() async -> [DiscoveredDevice] {
        async let ssdp = ssdpScanner.scan(timeout: 3.0)
        async let bonjour = bonjourScanner.scan(timeout: 3.0)
        let devices = await (ssdp + bonjour)
        return Array(Set(devices))
    }
}
