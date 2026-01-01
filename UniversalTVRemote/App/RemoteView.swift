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
            VStack(spacing: 16) {
                Text(viewModel.status)
                    .font(.headline)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                HStack(spacing: 16) {
                    if viewModel.supports(command: .power) {
                        RemoteButton(title: "Power", systemImage: "power") {
                            trigger(.power)
                        }
                    }
                    if viewModel.supports(command: .home) {
                        RemoteButton(title: "Home", systemImage: "house") {
                            trigger(.home)
                        }
                    }
                    if viewModel.supports(command: .back) {
                        RemoteButton(title: "Back", systemImage: "arrow.backward") {
                            trigger(.back)
                        }
                    }
                }

                if viewModel.supports(command: .ok) {
                    DirectionPad(onTap: trigger)
                }

                if viewModel.supports(.touchpad) {
                    TouchpadView { command in
                        trigger(command)
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.supports(command: .volumeUp) {
                        RemoteButton(title: "Volume +", systemImage: "speaker.wave.2") { trigger(.volumeUp) }
                    }
                    if viewModel.supports(command: .mute) {
                        RemoteButton(title: "Mute", systemImage: "speaker.slash") { trigger(.mute) }
                    }
                    if viewModel.supports(command: .volumeDown) {
                        RemoteButton(title: "Volume -", systemImage: "speaker.wave.1") { trigger(.volumeDown) }
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.supports(command: .play) {
                        RemoteButton(title: "Play", systemImage: "play.fill") { trigger(.play) }
                    }
                    if viewModel.supports(command: .pause) {
                        RemoteButton(title: "Pause", systemImage: "pause.fill") { trigger(.pause) }
                    }
                    if viewModel.supports(command: .menu) {
                        RemoteButton(title: "Menu", systemImage: "line.3.horizontal") { trigger(.menu) }
                    }
                }

                HStack(spacing: 16) {
                    if viewModel.supports(command: .channelUp) {
                        RemoteButton(title: "CH +", systemImage: "chevron.up") { trigger(.channelUp) }
                    }
                    if viewModel.supports(command: .channelDown) {
                        RemoteButton(title: "CH -", systemImage: "chevron.down") { trigger(.channelDown) }
                    }
                }

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

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.secondary.opacity(0.2))
            .frame(height: 120)
            .overlay(Text("Pavé tactile").font(.caption))
            .onTapGesture {
                onSwipe(.ok)
            }
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        if abs(horizontal) > abs(vertical) {
                            onSwipe(horizontal > 0 ? .right : .left)
                        } else {
                            onSwipe(vertical > 0 ? .down : .up)
                        }
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
