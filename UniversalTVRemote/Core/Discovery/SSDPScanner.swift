// File: Core/Discovery/SSDPScanner.swift

import Foundation
@preconcurrency import Network
import OSLog

public protocol SSDPScanning {
    func scan(timeout: TimeInterval) async -> [DiscoveredDevice]
    func parseSSDPResponse(_ data: Data) -> [String: String]
}

public final class SSDPScanner: SSDPScanning {
    private let multicastHost = NWEndpoint.Host("239.255.255.250")
    private let multicastPort = NWEndpoint.Port(rawValue: 1900)!
    private let logger = AppLogger.discovery
    private let lgServiceType = "urn:lge-com:service:webos-second-screen:1"

    public nonisolated static let defaultTimeout: TimeInterval = {
    #if DEBUG
        return 7.0
    #else
        return 3.0
    #endif
    }()

    public init() {}

    public func scan(timeout: TimeInterval = SSDPScanner.defaultTimeout) async -> [DiscoveredDevice] {
        logger.info("SSDP startScan (timeout \(timeout, privacy: .public)s)")
        guard let path = await currentNetworkPath() else {
            logger.warning("SSDP scan annulé: impossible de récupérer l'état réseau")
            return []
        }

        let interfaceDescription = pathInterfaceDescription(path)
        logger.info(
            "SSDP path status=\(path.status.logDescription, privacy: .public) supportsIPv4=\(path.supportsIPv4, privacy: .public) interface=\(interfaceDescription, privacy: .public)"
        )

        guard path.status == .satisfied, path.supportsIPv4 else {
            logger.warning("SSDP scan annulé: réseau non satisfait ou IPv4 indisponible")
            return []
        }

        let parameters = NWParameters.udp
        let multicastEndpoint = NWEndpoint.hostPort(host: multicastHost, port: multicastPort)
        let multicastGroup: NWMulticastGroup
        do {
            multicastGroup = try NWMulticastGroup(for: [multicastEndpoint])
        } catch {
            logger.error("SSDP erreur création multicast group: \(error.localizedDescription, privacy: .public)")
            return []
        }

        let group = NWConnectionGroup(with: multicastGroup, using: parameters)
        var results: [DiscoveredDevice] = []
        var responsesReceived = 0
        var fallbackSent = false
        let fallbackDelay: TimeInterval = 1.0
        let fallbackDeadline = Date().addingTimeInterval(fallbackDelay)
        let queue = DispatchQueue(label: "ssdp-scanner")

        group.stateUpdateHandler = { [logger] state in
            switch state {
            case .setup:
                logger.info("SSDP état groupe: setup")
            case .waiting(let error):
                logger.warning("SSDP état groupe: waiting \(error.localizedDescription, privacy: .public)")
            case .ready:
                logger.info("SSDP groupe ready")
            case .failed(let error):
                logger.error("SSDP état groupe: failed \(error.localizedDescription, privacy: .public)")
            case .cancelled:
                logger.info("SSDP état groupe: cancelled")
            @unknown default:
                logger.warning("SSDP état groupe: inconnu")
            }
        }

        let responsesStream = AsyncStream<SSDPResponse> { continuation in
            group.setReceiveHandler(maximumMessageSize: 65_535, rejectOversizedMessages: true) { message, data, isComplete in
                guard isComplete, let data else { return }
                let remoteEndpoint = message.remoteEndpoint
                self.logger.info(
                    "SSDP réponse reçue (octets \(data.count, privacy: .public)) remote=\(remoteEndpoint?.debugDescription ?? "unknown", privacy: .public)"
                )
                if let payload = String(data: data, encoding: .utf8) {
                    let lines = payload
                        .split(whereSeparator: \.isNewline)
                        .prefix(3)
                        .map { AppLogger.truncate(String($0), maxLength: 160) }
                    if !lines.isEmpty {
                        AppLogger.debugIfVerbose(
                            "SSDP payload (3 lignes max): \(lines.joined(separator: " | "))",
                            logger: self.logger
                        )
                    }
                }
                continuation.yield(SSDPResponse(data: data, remoteEndpoint: remoteEndpoint))
            }
        }

        group.start(queue: queue)
        sendSearchMessage(group, endpoint: multicastEndpoint, searchTarget: lgServiceType)

        let endDate = Date().addingTimeInterval(timeout)
        var iterator = responsesStream.makeAsyncIterator()
        while Date() < endDate {
            let remaining = endDate.timeIntervalSinceNow
            guard remaining > 0 else { break }

            if !fallbackSent && responsesReceived == 0 && Date() >= fallbackDeadline {
                sendSearchMessage(group, endpoint: multicastEndpoint, searchTarget: "ssdp:all")
                fallbackSent = true
            }

            do {
                let response = try await withTimeout(remaining) {
                    await iterator.next()
                }

                if let response = response ?? nil {
                    responsesReceived += 1
                    let headers = parseSSDPResponse(response.data)
                    if let device = buildDevice(from: headers, remoteEndpoint: response.remoteEndpoint) {
                        results.append(device)
                    } else {
                        AppLogger.debugIfVerbose("SSDP réponse non parsée (LOCATION absente ou invalide)", logger: logger)
                    }
                } else {
                    AppLogger.debugIfVerbose("SSDP timeout sans réponse", logger: logger)
                }
            } catch {
                logger.error("Erreur socket SSDP: \(error.localizedDescription, privacy: .public)")
                break
            }
        }

        group.cancel()

        if responsesReceived == 0 {
            logger.info("SSDP aucune réponse reçue")
            logger.info("SSDP hint: multicast bloqué / réseau invité / autorisation réseau local")
        } else if results.isEmpty {
            logger.info("SSDP réponses reçues mais non parsées")
        }

        logger.info("SSDP stopScan (réponses \(responsesReceived, privacy: .public), appareils \(results.count, privacy: .public))")
        return Array(Set(results))
    }

    public func parseSSDPResponse(_ data: Data) -> [String: String] {
        guard let response = String(data: data, encoding: .utf8) else { return [:] }

        var headers: [String: String] = [:]

        response
            .split(separator: "\r\n", omittingEmptySubsequences: true)
            .forEach { line in
                guard let colonIndex = line.firstIndex(of: ":") else { return }

                let key = line[..<colonIndex]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()

                let valueStart = line.index(after: colonIndex)
                let value = line[valueStart...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                headers[key] = value
            }

        return headers
    }

    private struct SSDPResponse {
        let data: Data
        let remoteEndpoint: NWEndpoint?
    }

    func buildDevice(from headers: [String: String], remoteEndpoint: NWEndpoint?) -> DiscoveredDevice? {
        let st = headers["ST"] ?? ""
        let usn = headers["USN"] ?? ""
        let server = headers["SERVER"] ?? ""
        let location = headers["LOCATION"] ?? ""

        let type = inferType(st: st, usn: usn, server: server)

        let host = extractHost(from: location, remoteEndpoint: remoteEndpoint)
        guard let host else {
            let keys = headers.keys.sorted().joined(separator: ", ")
            AppLogger.debugIfVerbose("SSDP LOCATION absente/invalide, headers présents: \(keys)", logger: logger)
            return nil
        }

        let port = (type == .lgWebOS) ? 3001 : URL(string: location)?.port
        let defaultName = headers["SERVER"] ?? headers["LOCATION"] ?? "Appareil SSDP"
        let name = (type == .lgWebOS) ? "LG webOS TV" : defaultName

        if type == .lgWebOS {
            let truncatedSt = AppLogger.truncate(st, maxLength: 80)
            let truncatedUsn = AppLogger.truncate(usn, maxLength: 80)
            logger.info(
                "LG webOS détectée ip=\(host, privacy: .public) st=\(truncatedSt, privacy: .public) usn=\(truncatedUsn, privacy: .public)"
            )
        }

        return DiscoveredDevice(
            name: name,
            ipAddress: host,
            port: port,
            type: type,
            metadata: headers
        )
    }

    private func inferType(st: String, usn: String, server: String) -> DeviceType {
        let lower = (st + usn + server).lowercased()
        if lower.contains("roku") { return .roku }
        if lower.contains("google") || lower.contains("chromecast") { return .chromecast }
        if lower.contains(lgServiceType) { return .lgWebOS }
        if lower.contains("webos") { return .lgWebOS }
        if lower.contains("dlna") || lower.contains("upnp") { return .dlnaGeneric }
        return .unknown
    }

    private func sendSearchMessage(_ group: NWConnectionGroup, endpoint: NWEndpoint, searchTarget: String) {
        let message =
            "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "MX: 2\r\n" +
            "ST: \(searchTarget)\r\n\r\n"

        guard let data = message.data(using: .utf8) else { return }

        logger.info("SSDP envoi recherche ST=\(searchTarget, privacy: .public)")

        // NWConnectionGroup requires a Message describing send metadata.
        let msg = NWConnectionGroup.Message(identifier: "ssdp-\(UUID().uuidString)")
        group.send(content: data, to: endpoint, message: msg) { error in
            if let error {
                self.logger.error("SSDP send error: \(error.localizedDescription, privacy: .public)")
            } else {
                self.logger.info("SSDP envoi confirmé ST=\(searchTarget, privacy: .public)")
            }
        }
    }

    private func extractHost(from location: String, remoteEndpoint: NWEndpoint?) -> String? {
        if let host = URL(string: location)?.host {
            return host
        }
        guard let remoteEndpoint else { return nil }
        if case let .hostPort(host, _) = remoteEndpoint {
            return host.debugDescription
        }
        return nil
    }

    private func currentNetworkPath(timeout: TimeInterval = 1.0) async -> NWPath? {
        await withCheckedContinuation { (continuation: CheckedContinuation<NWPath?, Never>) in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "ssdp-path-monitor")

            var didResume = false

            func finish(_ path: NWPath?) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: path)
                monitor.cancel()
            }

            monitor.pathUpdateHandler = { updatedPath in
                finish(updatedPath)
            }

            monitor.start(queue: queue)

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(nil)
            }
        }
    }

    private func pathInterfaceDescription(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.wiredEthernet) { return "wiredEthernet" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        if path.usesInterfaceType(.loopback) { return "loopback" }
        if path.usesInterfaceType(.other) { return "other" }
        return "unknown"
    }
}

private extension NWPath.Status {
    var logDescription: String {
        switch self {
        case .satisfied: return "satisfied"
        case .unsatisfied: return "unsatisfied"
        case .requiresConnection: return "requiresConnection"
        @unknown default: return "unknown"
        }
    }
}
