// File: App/RemoteView.swift

import SwiftUI
import Speech
import AVFoundation
import UIKit

struct RemoteView: View {
    @StateObject var viewModel: RemoteViewModel
    @State private var isListening = false
    @State private var voiceText = ""
    @State private var launchingStreamingApp: StreamingApp?
    private let voiceRouter = VoiceCommandRouter()

    init(viewModel: RemoteViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Status
                VStack(spacing: 6) {
                    Text(viewModel.status)
                        .font(.headline)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // POWER (full width)
                RemoteWideButton(
                    title: "POWER",
                    systemImage: "power",
                    isEnabled: true
                ) {
                    trigger(.power)
                }

                // Numeric keypad (digits enabled if driver supports .digit(n))
                VStack(alignment: .leading, spacing: 10) {
                    let digitsEnabled = viewModel.supports(command: .digit(0))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach([1,2,3,4,5,6,7,8,9], id: \.self) { n in
                            RemoteKeyButton(title: "\(n)", systemImage: nil, isEnabled: digitsEnabled) {
                                trigger(.digit(n))
                            }
                        }

                        RemoteKeyButton(title: "LIST/-", systemImage: nil, isEnabled: viewModel.supports(command: .list)) {
                            trigger(.list)
                        }

                        // 0 key is functional; keep the Quick label.
                        RemoteKeyButton(title: "0\n(Quick)", systemImage: nil, isEnabled: digitsEnabled) {
                            trigger(.digit(0))
                        }

                        RemoteKeyButton(title: "…\n(AD/SAP)", systemImage: nil, isEnabled: viewModel.supports(command: .adSap)) {
                            trigger(.adSap)
                        }
                    }

                    if !digitsEnabled {
                        Text("Les touches numériques seront activées quand le driver courant supportera .digit(n).")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // VOL +/-   MUTE   CH ▲/▼
                HStack(alignment: .center, spacing: 14) {
                    RockerGroup(title: "VOL", upIcon: "plus", downIcon: "minus", upEnabled: viewModel.supports(command: .volumeUp), downEnabled: viewModel.supports(command: .volumeDown)) {
                        trigger(.volumeUp)
                    } downAction: {
                        trigger(.volumeDown)
                    }

                    RemoteKeyButton(title: "MUTE", systemImage: "speaker.slash", isEnabled: viewModel.supports(command: .mute)) {
                        trigger(.mute)
                    }

                    RockerGroup(title: "CH", upIcon: "chevron.up", downIcon: "chevron.down", upEnabled: viewModel.supports(command: .channelUp), downEnabled: viewModel.supports(command: .channelDown)) {
                        trigger(.channelUp)
                    } downAction: {
                        trigger(.channelDown)
                    }
                }

                // HOME   VOICE (Mic)   INPUT (Source)
                HStack(spacing: 12) {
                    RemoteKeyButton(title: "HOME", systemImage: "house", isEnabled: viewModel.supports(command: .home)) {
                        trigger(.home)
                    }

                    RemoteKeyButton(title: "VOICE", systemImage: isListening ? "mic.fill" : "mic", isEnabled: true) {
                        toggleListening()
                    }

                    RemoteKeyButton(title: "INPUT\n(Source)", systemImage: "rectangle.on.rectangle", isEnabled: viewModel.supports(command: .input)) {
                        trigger(.input)
                    }
                }

                // NAVIGATION (OK + arrows)
                VStack(alignment: .leading, spacing: 10) {
                    Text("NAVIGATION")
                        .font(.headline)

                    if viewModel.supports(command: .ok) {
                        DirectionPad(onTap: trigger)
                    }
                }

                // PAVÉ TACTILE
                VStack(alignment: .leading, spacing: 10) {
                    Text("PAVÉ TACTILE")
                        .font(.headline)

                    if viewModel.supports(.touchpad) {
                        TouchpadView { command in
                            trigger(command)
                        }
                    } else {
                        Text("Non disponible pour cet appareil")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // BACK (Return)   SETTINGS (Gear)
                HStack(spacing: 12) {
                    RemoteKeyButton(title: "BACK\n(Return)", systemImage: "arrow.uturn.left", isEnabled: viewModel.supports(command: .back)) {
                        trigger(.back)
                    }

                    RemoteKeyButton(title: "SETTINGS\n(Gear)", systemImage: "gearshape", isEnabled: viewModel.supports(command: .settings)) {
                        trigger(.settings)
                    }
                }

                // ---- Advanced sections (keep existing features below) ----
                Divider().padding(.top, 8)

                // Playback row
                HStack(spacing: 12) {
                    if viewModel.supports(command: .play) {
                        RemoteButton(title: "Play", systemImage: "play.fill") { trigger(.play) }
                    }
                    if viewModel.supports(command: .pause) {
                        RemoteButton(title: "Pause", systemImage: "pause.fill") { trigger(.pause) }
                    }
                }

                // Quick text input
                if viewModel.supports(.textInput) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saisie rapide")
                            .font(.headline)
                        HStack {
                            TextField("Envoyer du texte…", text: $viewModel.quickText)
                                .textFieldStyle(.roundedBorder)
                            Button("Envoyer") {
                                Task { await viewModel.sendText() }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Voice commands (transcript + start/stop)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Commandes vocales")
                        .font(.headline)
                    HStack {
                        Text(voiceText.isEmpty ? "Dites une commande…" : voiceText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(isListening ? "Stop" : "Écouter") {
                            toggleListening()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                // Quick Apps (platform-specific)
                if viewModel.supports(.launcher) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Apps")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(LaunchableApp.allCases, id: \.self) { app in
                                    Button(app.rawValue.capitalized) {
                                        Task { await viewModel.launch(app) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                }

                // Streaming section
                if viewModel.hasStreamingProvider {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Streaming")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)]) {
                            ForEach(StreamingApp.allCases) { app in
                                VStack(spacing: 6) {
                                    Button {
                                        launchStreaming(app)
                                    } label: {
                                        HStack(spacing: 8) {
                                            if launchingStreamingApp == app {
                                                ProgressView()
                                            }
                                            Text(app.displayName)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(viewModel.streamingAppsLoaded && !viewModel.isStreamingAppAvailable(app))

                                    if viewModel.streamingAppsLoaded && !viewModel.isStreamingAppAvailable(app) {
                                        Text("Installer sur la TV")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .task {
            await viewModel.connect()
        }
    }

    private func trigger(_ command: RemoteCommand) {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        Task { await viewModel.send(command) }
    }

    private func toggleListening() {
        if isListening {
            isListening = false
            SpeechRecognizer.shared.stop()
        } else {
            isListening = true
            SpeechRecognizer.shared.start { transcript in
                voiceText = transcript
                if let command = voiceRouter.map(text: transcript) {
                    Task { await viewModel.send(command) }
                }
            }
        }
    }

    private func launchStreaming(_ app: StreamingApp) {
        launchingStreamingApp = app
        Task {
            let success = await viewModel.launchStreaming(app)
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(success ? .success : .error)
            launchingStreamingApp = nil
        }
    }
}

private struct RemoteButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                Text(title)
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

private struct RemoteWideButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.45)
    }
}

private struct RemoteKeyButton: View {
    let title: String
    let systemImage: String?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.45)
    }
}

private struct RockerGroup: View {
    let title: String
    let upIcon: String
    let downIcon: String
    let upEnabled: Bool
    let downEnabled: Bool
    let upAction: () -> Void
    let downAction: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: upAction) {
                Image(systemName: upIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!upEnabled)
            .opacity(upEnabled ? 1.0 : 0.45)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Button(action: downAction) {
                Image(systemName: downIcon)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!downEnabled)
            .opacity(downEnabled ? 1.0 : 0.45)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct CircleIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 56, height: 56)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
    }
}

private struct IconPillButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: 56, height: 44)
        }
        .buttonStyle(.bordered)
    }
}

private struct DirectionPad: View {
    let onTap: (RemoteCommand) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: { onTap(.up) }) {
                Image(systemName: "chevron.up")
                    .padding(12)
            }
            HStack(spacing: 12) {
                Button(action: { onTap(.left) }) {
                    Image(systemName: "chevron.left")
                        .padding(12)
                }
                Button(action: { onTap(.ok) }) {
                    Text("OK")
                        .font(.headline)
                        .padding(12)
                }
                Button(action: { onTap(.right) }) {
                    Image(systemName: "chevron.right")
                        .padding(12)
                }
            }
            Button(action: { onTap(.down) }) {
                Image(systemName: "chevron.down")
                    .padding(12)
            }
        }
        .buttonStyle(.bordered)
    }
}

private struct TouchpadView: View {
    let onSwipe: (RemoteCommand) -> Void

    // Use incremental deltas to avoid sending many commands for a single long drag.
    @State private var lastTranslation: CGSize = .zero
    @State private var lastSentAt: TimeInterval = 0

    // Slower + less sensitive than before.
    private let sendInterval: TimeInterval = 0.18
    private let step: CGFloat = 26

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 140)
            .overlay(
                VStack(spacing: 6) {
                    Text("Pavé tactile")
                        .font(.caption)
                    Text("Glissez pour naviguer • Tap pour OK")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            )
            .onTapGesture {
                onSwipe(.ok)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let now = Date().timeIntervalSince1970
                        guard now - lastSentAt >= sendInterval else { return }

                        // Compute delta since last time we acted.
                        let dx = value.translation.width - lastTranslation.width
                        let dy = value.translation.height - lastTranslation.height

                        guard abs(dx) >= step || abs(dy) >= step else { return }

                        if abs(dx) > abs(dy) {
                            onSwipe(dx > 0 ? .right : .left)
                            // Advance the reference point by one step in that direction.
                            lastTranslation.width += dx > 0 ? step : -step
                        } else {
                            onSwipe(dy > 0 ? .down : .up)
                            lastTranslation.height += dy > 0 ? step : -step
                        }

                        lastSentAt = now
                    }
                    .onEnded { _ in
                        // Reset for the next gesture.
                        lastTranslation = .zero
                    }
            )
    }
}

final class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    static let shared = SpeechRecognizer()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func start(onResult: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else { return }
            DispatchQueue.main.async {
                self.startSession(onResult: onResult)
            }
        }
    }

    func stop() {
        audioEngine.stop()
        request?.endAudio()
        task?.cancel()
    }

    private func startSession(onResult: @escaping (String) -> Void) {
        request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request?.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        task = recognizer?.recognitionTask(with: request ?? SFSpeechAudioBufferRecognitionRequest()) { result, _ in
            if let result {
                onResult(result.bestTranscription.formattedString)
            }
        }
    }
}
