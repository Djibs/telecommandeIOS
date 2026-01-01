// File: Drivers/LG/LGWebOSService.swift

import Foundation
import WebOSClient
import os

@MainActor
public enum LGWebOSConnectionState: Equatable {
    case disconnected
    case connecting
    case awaitingPrompt
    case awaitingPin
    case registering
    case ready
    case error(String)
}

@MainActor
public protocol LGWebOSControlling: AnyObject {
    var state: LGWebOSConnectionState { get }
    var hasStoredClientKey: Bool { get }
    var deviceIdentifier: String { get }

    func ensureReady(pairingType: WebOSPairingType?) async throws
    func disconnect()
    func restartPairing(pairingType: WebOSPairingType) async
    func setPin(_ pin: String)
    func send(_ target: WebOSTarget)
    func sendKey(_ key: WebOSKeyTarget)
    func sendRequest(_ target: WebOSTarget) async throws -> WebOSResponse
}

@MainActor
public final class LGWebOSService: NSObject, ObservableObject, LGWebOSControlling, LGWebOSRequesting {
    @Published public private(set) var state: LGWebOSConnectionState = .disconnected

    public var hasStoredClientKey: Bool {
        (try? keychainStore.get(keychainKey)) != nil
    }
    public var deviceIdentifier: String {
        if let deviceId {
            return "lgwebos.\(deviceId)"
        }
        return "lgwebos.\(device.ipAddress)"
    }

    private let device: DiscoveredDevice
    private let keychainStore: KeychainStoring
    private let logger = Logger(subsystem: "UniversalTVRemote", category: "LGWebOS")
    private let clientFactory: (URL, WebOSClientDelegate?) -> WebOSClientProtocol

    private var client: WebOSClientProtocol?
    private var currentPairingType: WebOSPairingType = .prompt
    private var isConnected = false
    private var attemptedFallback = false
    private var pendingContinuations: [CheckedContinuation<Void, Error>] = []
    private var responseContinuations: [String: CheckedContinuation<WebOSResponse, Error>] = [:]
    private var deviceId: String?

    private var keychainKey: String {
        "lgwebos.clientKey.\(device.ipAddress)"
    }

    public init(
        device: DiscoveredDevice,
        keychainStore: KeychainStoring = KeychainStore(),
        clientFactory: @escaping (URL, WebOSClientDelegate?) -> WebOSClientProtocol = { url, delegate in
            WebOSClient(url: url, delegate: delegate, shouldLogActivity: false)
        }
    ) {
        self.device = device
        self.keychainStore = keychainStore
        self.clientFactory = clientFactory
        super.init()
    }

    public func ensureReady(pairingType: WebOSPairingType? = nil) async throws {
        if case .ready = state { return }
        if let pairingType {
            currentPairingType = pairingType
        }
        try await withCheckedThrowingContinuation { continuation in
            pendingContinuations.append(continuation)
            if case .disconnected = state {
                connect()
            } else if case .error = state {
                connect()
            }
        }
    }

    public func restartPairing(pairingType: WebOSPairingType) async {
        currentPairingType = pairingType
        disconnect()
        state = .disconnected
        connect()
    }

    public func disconnect() {
        client?.disconnect()
        client = nil
        isConnected = false
        state = .disconnected
    }

    public func setPin(_ pin: String) {
        guard !pin.isEmpty else { return }
        state = .registering
        client?.send(.setPin(pin))
    }

    public func send(_ target: WebOSTarget) {
        client?.send(target)
    }

    public func sendKey(_ key: WebOSKeyTarget) {
        client?.sendKey(key)
    }

    public func sendRequest(_ target: WebOSTarget) async throws -> WebOSResponse {
        guard let client else { throw RemoteError.connectionFailed }
        return try await withCheckedThrowingContinuation { continuation in
            let id = UUID().uuidString.lowercased()
            responseContinuations[id] = continuation
            if client.send(target, id: id) == nil {
                responseContinuations.removeValue(forKey: id)
                continuation.resume(throwing: RemoteError.invalidResponse)
            }
        }
    }

    private func connect() {
        state = .connecting
        isConnected = false
        attemptedFallback = false
        connect(usingSecureSocket: true)
    }

    private func connect(usingSecureSocket: Bool) {
        let scheme = usingSecureSocket ? "wss" : "ws"
        let port = usingSecureSocket ? 3001 : 3000
        guard let url = URL(string: "\(scheme)://\(device.ipAddress):\(port)") else {
            transitionToError("URL WebSocket invalide")
            return
        }
        logger.info("Connexion WebOS via \(scheme, privacy: .public)://\(self.device.ipAddress, privacy: .public):\(port, privacy: .public)")
        client = clientFactory(url, self)
        client?.connect()
    }

    private func register() {
        state = .registering
        let clientKeyData = (try? keychainStore.get(keychainKey)) ?? nil
        let clientKey = clientKeyData.flatMap { String(data: $0, encoding: .utf8) }
        client?.send(.register(pairingType: currentPairingType, clientKey: clientKey))
    }

    private func transitionToError(_ message: String) {
        state = .error(message)
        resumePendingContinuations(error: RemoteError.network(message))
    }

    private func resumePendingContinuations(success: Bool = false, error: Error? = nil) {
        let continuations = pendingContinuations
        pendingContinuations.removeAll()
        continuations.forEach { continuation in
            if let error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: ())
            }
        }
    }
}

extension LGWebOSService: WebOSClientDelegate {
    public func didConnect() {
        isConnected = true
        register()
    }

    public func didPrompt() {
        state = .awaitingPrompt
    }

    public func didDisplayPin() {
        state = .awaitingPin
    }

    public func didRegister(with clientKey: String) {
        do {
            if let data = clientKey.data(using: .utf8) {
                try keychainStore.set(data, forKey: keychainKey)
            }
            state = .ready
            resumePendingContinuations(success: true)
            Task {
                do {
                    let response = try await sendRequest(.systemInfo)
                    if let deviceId = response.payload?.deviceId {
                        self.deviceId = deviceId
                    }
                } catch {
                    logger.warning("Erreur systemInfo: \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            transitionToError("Impossible de sauvegarder le clientKey: \(error.localizedDescription)")
        }
    }

    public func didReceive(_ result: Result<WebOSResponse, Error>) {
        switch result {
        case .success(let response):
            if let deviceId = response.payload?.deviceId {
                self.deviceId = deviceId
            }
            if let responseId = response.id,
               let continuation = responseContinuations.removeValue(forKey: responseId) {
                continuation.resume(returning: response)
            }
        case .failure(let error):
            responseContinuations.values.forEach { $0.resume(throwing: error) }
            responseContinuations.removeAll()
        }
    }

    public func didReceiveNetworkError(_ error: Error?) {
        let message = error?.localizedDescription ?? "Erreur réseau inconnue"
        responseContinuations.values.forEach { $0.resume(throwing: RemoteError.network(message)) }
        responseContinuations.removeAll()
        if !isConnected, !attemptedFallback {
            attemptedFallback = true
            logger.warning("Échec WSS, fallback WS: \(message, privacy: .public)")
            connect(usingSecureSocket: false)
            return
        }
        logger.error("Erreur réseau WebOS: \(message, privacy: .public)")
        transitionToError(message)
    }

    public func didDisconnect() {
        state = .disconnected
    }
}
