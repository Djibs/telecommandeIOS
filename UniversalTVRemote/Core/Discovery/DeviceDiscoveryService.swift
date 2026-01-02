// File: Core/Discovery/DeviceDiscoveryService.swift

import Foundation

public protocol DeviceDiscoveryService {
    func scan() async -> [DiscoveredDevice]
}

public final class CompositeDiscoveryService: DeviceDiscoveryService {
    private let ssdpScanner: SSDPScanning
    private let bonjourScanner: BonjourScanning

    public init(
        ssdpScanner: SSDPScanning = SSDPScanner(),
        bonjourScanner: BonjourScanning
    ) {
        self.ssdpScanner = ssdpScanner
        self.bonjourScanner = bonjourScanner
    }

    @MainActor
    public static func makeDefault() -> CompositeDiscoveryService {
        CompositeDiscoveryService(
            ssdpScanner: SSDPScanner(),
            bonjourScanner: BonjourScanner()
        )
    }

    public static var defaultBonjourTimeout: TimeInterval {
#if DEBUG
        9.0
#else
        3.0
#endif
    }

    public static var defaultSSDPTimeout: TimeInterval {
        SSDPScanner.defaultTimeout
    }

    public func scan() async -> [DiscoveredDevice] {
        async let ssdp = ssdpScanner.scan(timeout: Self.defaultSSDPTimeout)
        async let bonjour = bonjourScanner.scan(timeout: Self.defaultBonjourTimeout)
        let devices = await (ssdp + bonjour)
        var uniqueDevices: [DeviceKey: DiscoveredDevice] = [:]
        for device in devices {
            let key = DeviceKey(ipAddress: device.ipAddress, type: device.type)
            if uniqueDevices[key] == nil {
                uniqueDevices[key] = device
            }
        }
        return Array(uniqueDevices.values)
    }
}

private struct DeviceKey: Hashable {
    let ipAddress: String
    let type: DeviceType
}
