// File: Core/Discovery/SSDPScanner.swift

import Foundation
import Network
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
        let parameters = NWParameters.udp
        let connection = NWConnection(host: multicastHost, port: multicastPort, using: parameters)
        var results: [DiscoveredDevice] = []
        var responsesReceived = 0
        var fallbackSent = false
        let fallbackDelay: TimeInterval = 1.0
        let fallbackDeadline = Date().addingTimeInterval(fallbackDelay)
        let queue = DispatchQueue(label: "ssdp-scanner")

        connection.start(queue: queue)
        logger.info("SSDP startScan (timeout \(timeout, privacy: .public)s)")
        sendSearchMessage(connection, searchTarget: lgServiceType)

        let endDate = Date().addingTimeInterval(timeout)
        while Date() < endDate {
            let remaining = endDate.timeIntervalSinceNow
            guard remaining > 0 else { break }

            if !fallbackSent && responsesReceived == 0 && Date() >= fallbackDeadline {
                sendSearchMessage(connection, searchTarget: "ssdp:all")
                fallbackSent = true
            }

            do {
                // withTimeout(T, op) retourne souvent T? ; receiveOnce retourne SSDPResponse?
                // => résultat SSDPResponse?? (double optionnel) qu’on aplatit via `?? nil`
                let response = try await withTimeout(remaining) {
                    try await self.receiveOnce(from: connection)
                }

                if let response = response ?? nil {
                    responsesReceived += 1
                    let headers = parseSSDPResponse(response.data)
                    if let device = buildDevice(from: headers) {
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

        connection.cancel()

        if responsesReceived == 0 {
            logger.info("SSDP aucune réponse reçue")
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

    // MARK: - Private

    private struct SSDPResponse {
        let data: Data
    }

    private func receiveOnce(from connection: NWConnection) async throws -> SSDPResponse? {
        try await withCheckedThrowingContinuation { continuation in
            connection.receiveMessage { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard isComplete, let data else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: SSDPResponse(data: data))
            }
        }
    }

    private func buildDevice(from headers: [String: String]) -> DiscoveredDevice? {
        let st = headers["ST"] ?? ""
        let usn = headers["USN"] ?? ""
        let server = headers["SERVER"] ?? ""
        let location = headers["LOCATION"] ?? ""

        let type = inferType(st: st, usn: usn, server: server)

        // SSDP: on déduit l’IP depuis LOCATION (le plus fiable ici)
        guard let host = URL(string: location)?.host else { return nil }

        let port = (type == .lgWebOS) ? 3001 : URL(string: location)?.port
        let defaultName = headers["SERVER"] ?? headers["LOCATION"] ?? "Appareil SSDP"
        let name = (type == .lgWebOS) ? "LG webOS TV" : defaultName

        if type == .lgWebOS {
            let truncatedSt = AppLogger.truncate(st, maxLength: 80)
            let truncatedUsn = AppLogger.truncate(usn, maxLength: 80)
            logger.info("LG webOS détectée \(host, privacy: .public) st=\(truncatedSt, privacy: .public) usn=\(truncatedUsn, privacy: .public)")
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

    private func sendSearchMessage(_ connection: NWConnection, searchTarget: String) {
        let message =
            "M-SEARCH * HTTP/1.1\r\n" +
            "HOST: 239.255.255.250:1900\r\n" +
            "MAN: \"ssdp:discover\"\r\n" +
            "MX: 2\r\n" +
            "ST: \(searchTarget)\r\n\r\n"

        guard let data = message.data(using: .utf8) else { return }

        connection.send(content: data, completion: .contentProcessed { error in
            if let error {
                self.logger.error("SSDP send error: \(error.localizedDescription, privacy: .public)")
            }
        })
    }
}
