// File: App/CastingView.swift

import SwiftUI
import PhotosUI

struct CastingView: View {
    @StateObject var viewModel: CastingViewModel

    init(viewModel: CastingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Diffuser un média")
                .font(.title2.bold())

            PhotosPicker(selection: $viewModel.selectedItem, matching: .any(of: [.images, .videos])) {
                Label("Choisir une photo/vidéo", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.borderedProminent)

            Button("Caster") {
                Task { await viewModel.castSelectedItem() }
            }
            .buttonStyle(.bordered)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Text("Astuce : si l'appareil ne supporte pas le casting LAN, utilisez AirPlay via la feuille de partage iOS.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
