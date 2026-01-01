// File: Core/Discovery/BonjourScanner.swift

import Foundation

public protocol BonjourScanning {
    func scan(timeout: TimeInterval) async -> [DiscoveredDevice]
}

public final class BonjourScanner: NSObject, BonjourScanning, NetServiceBrowserDelegate, NetServiceDelegate {
    private var services: [NetService] = []
    private var devices: [DiscoveredDevice] = []
    private var continuation: CheckedContinuation<[DiscoveredDevice], Never>?

    public func scan(timeout: TimeInterval = 3.0) async -> [DiscoveredDevice] {
        services = []
        devices = []
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.searchForServices(ofType: "_roku._tcp.", inDomain: "local.")
        browser.searchForServices(ofType: "_googlecast._tcp.", inDomain: "local.")

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                browser.stop()
                continuation.resume(returning: self.devices)
            }
        }
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 2.0)
        services.append(service)
    }

    public func netServiceDidResolveAddress(_ sender: NetService) {
        let host = sender.hostName?.replacingOccurrences(of: ".local.", with: "") ?? sender.name
        let type: DeviceType
        if sender.type.contains("roku") {
            type = .roku
        } else if sender.type.contains("googlecast") {
            type = .chromecast
        } else {
            type = .unknown
        }
        let device = DiscoveredDevice(
            name: sender.name,
            ipAddress: host,
            port: sender.port,
            type: type,
            metadata: ["BonjourType": sender.type]
        )
        devices.append(device)
    }
}
