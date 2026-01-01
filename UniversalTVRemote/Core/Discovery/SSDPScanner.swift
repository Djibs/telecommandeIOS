// File: Core/Discovery/SSDPScanner.swift

import Foundation
import Network

public protocol SSDPScanning {
    func scan(timeout: TimeInterval) async -> [DiscoveredDevice]
    func parseSSDPResponse(_ data: Data) -> [String: String]
}

public final class SSDPScanner: SSDPScanning {
    private let multicastHost = NWEndpoint.Host("239.255.255.250")
    private let multicastPort = NWEndpoint.Port(rawValue: 1900)!

    public init() {}

    public func scan(timeout: TimeInterval = 3.0) async -> [DiscoveredDevice] {
        let parameters = NWParameters.udp
        let connection = NWConnection(host: multicastHost, port: multicastPort, using: parameters)
        var results: [DiscoveredDevice] = []
        let queue = DispatchQueue(label: "ssdp-scanner")

        connection.start(queue: queue)
        let message = "M-SEARCH * HTTP/1.1\r\n" +
        "HOST: 239.255.255.250:1900\r\n" +
        "MAN: \"ssdp:discover\"\r\n" +
        "MX: 2\r\n" +
        "ST: ssdp:all\r\n\r\n"

        if let data = message.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed { _ in })
        }

        let endDate = Date().addingTimeInterval(timeout)
        while Date() < endDate {
            do {
                let response = try await receiveOnce(from: connection)
                if let responseData = response {
                    let headers = parseSSDPResponse(responseData)
                    if let location = headers["LOCATION"],
                       let device = buildDevice(from: headers, location: location) {
                        results.append(device)
                    }
                }
            } catch {
                break
            }
        }

        connection.cancel()
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

    private func receiveOnce(from connection: NWConnection) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            connection.receiveMessage { data, _, isComplete, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard isComplete else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: data)
            }
        }
    }

    private func buildDevice(from headers: [String: String], location: String) -> DiscoveredDevice? {
        let st = headers["ST"] ?? ""
        let usn = headers["USN"] ?? ""
        let type = inferType(st: st, usn: usn)
        guard let host = URL(string: location)?.host else { return nil }
        let port = URL(string: location)?.port
        let name = headers["SERVER"] ?? headers["LOCATION"] ?? "Appareil SSDP"
        return DiscoveredDevice(name: name, ipAddress: host, port: port, type: type, metadata: headers)
    }

    private func inferType(st: String, usn: String) -> DeviceType {
        let lower = (st + usn).lowercased()
        if lower.contains("roku") { return .roku }
        if lower.contains("google") || lower.contains("chromecast") { return .chromecast }
        if lower.contains("dlna") || lower.contains("upnp") { return .dlnaGeneric }
        return .unknown
    }
}
