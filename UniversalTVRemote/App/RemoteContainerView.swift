// File: App/RemoteContainerView.swift

import SwiftUI

struct RemoteContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let driver = appState.driverForSelectedDevice() {
            RemoteView(viewModel: RemoteViewModel(driver: driver))
        } else {
            VStack(spacing: 12) {
                Text("Sélectionnez un appareil dans l'onglet Appareils.")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
