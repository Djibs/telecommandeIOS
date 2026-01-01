// File: Drivers/DriverRegistry.swift

import Foundation

public protocol DriverRegistry {
    func driver(for device: DiscoveredDevice) -> TVDriver
}

public final class DefaultDriverRegistry: DriverRegistry {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    public func driver(for device: DiscoveredDevice) -> TVDriver {
        switch device.type {
        case .roku:
            return RokuDriver(device: device, httpClient: httpClient)
        case .chromecast:
            return CastDriver(device: device)
        case .lgWebOS:
            return LGWebOSDriver(device: device)
        case .samsungTizen:
            return SamsungTizenDriver(device: device)
        case .sonyBravia:
            return SonyBraviaDriver(device: device, httpClient: httpClient)
        case .dlnaGeneric:
            return DLNAGenericDriver(device: device, httpClient: httpClient)
        case .unknown:
            return StubDriver(device: device)
        }
    }
}
