// File: Core/Discovery/BonjourScanner.swift

import Foundation
import OSLog

public protocol BonjourScanning {
    func scan(timeout: TimeInterval) async -> [DiscoveredDevice]
}

@MainActor
public final class BonjourScanner: NSObject, BonjourScanning, NetServiceBrowserDelegate, NetServiceDelegate {
    private var services: [NetService] = []
    private var devices: [DiscoveredDevice] = []
    private var continuation: CheckedContinuation<[DiscoveredDevice], Never>?
    private var browsers: [NetServiceBrowser] = []
    private var browserTypes: [ObjectIdentifier: String] = [:]
    private var timeoutWorkItem: DispatchWorkItem?
    private var isSearching = false
    private var scanId = 0
    private var activeScanId = 0
    private let logger = AppLogger.discovery
    private let browserFactory: (String) -> NetServiceBrowser

    private let serviceTypes: [String] = [
        "_roku._tcp.",
        "_googlecast._tcp."
    ]

    public init(browserFactory: @escaping (String) -> NetServiceBrowser = { _ in NetServiceBrowser() }) {
        self.browserFactory = browserFactory
        super.init()
    }

    public nonisolated static var defaultTimeout: TimeInterval {
    #if DEBUG
        9.0
    #else
        3.0
    #endif
    }

    public func scan(timeout: TimeInterval = BonjourScanner.defaultTimeout) async -> [DiscoveredDevice] {
        await withCheckedContinuation { continuation in
            startScan(timeout: timeout, continuation: continuation)
        }
    }

    private func startScan(timeout: TimeInterval, continuation: CheckedContinuation<[DiscoveredDevice], Never>) {
        if isSearching {
            logger.info("Bonjour scan déjà actif scanId=\(self.activeScanId, privacy: .public) - arrêt avant relance")
            finishScan(reason: "relance")
        }
        services = []
        devices = []
        scanId += 1
        activeScanId = scanId
        self.continuation = continuation
        isSearching = true
        logger.info("Bonjour startScan scanId=\(self.activeScanId, privacy: .public) (timeout \(timeout, privacy: .public)s)")
        browsers = serviceTypes.map { type in
            let browser = browserFactory(type)
            browser.delegate = self
            browserTypes[ObjectIdentifier(browser)] = type
            browser.searchForServices(ofType: type, inDomain: "local.")
            return browser
        }

        timeoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishScan(reason: "timeout")
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: workItem)
    }

    private func finishScan(reason: String) {
        guard isSearching else { return }
        let currentScanId = activeScanId
        browsers.forEach { $0.stop() }
        browsers = []
        browserTypes = [:]
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        isSearching = false
        logger.info("Bonjour stopScan scanId=\(currentScanId, privacy: .public) reason=\(reason, privacy: .public) (appareils \(self.devices.count, privacy: .public))")
        continuation?.resume(returning: devices)
        continuation = nil
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        service.resolve(withTimeout: 2.0)
        services.append(service)
    }

    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        logger.info("Bonjour willSearch scanId=\(self.activeScanId, privacy: .public) type=\(browserType(for: browser), privacy: .public)")
    }

    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        logger.info("Bonjour didStopSearch scanId=\(self.activeScanId, privacy: .public) type=\(browserType(for: browser), privacy: .public)")
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
        AppLogger.debugIfVerbose("Bonjour service résolu scanId=\(activeScanId) \(sender.name) \(host,)", logger: logger)
    }

    public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        logger.error("Bonjour resolve error scanId=\(self.activeScanId, privacy: .public) \(sender.name, privacy: .public): \(errorDict.description, privacy: .public)")
    }

    public func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        logger.error("Bonjour search error scanId=\(self.activeScanId, privacy: .public) type=\(browserType(for: browser), privacy: .public): \(errorDict.description, privacy: .public)")
        finishScan(reason: "didNotSearch")
    }

    private func browserType(for browser: NetServiceBrowser) -> String {
        browserTypes[ObjectIdentifier(browser)] ?? "unknown"
    }
}
