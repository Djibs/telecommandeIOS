// File: App/CastingContainerView.swift

import SwiftUI

struct CastingContainerView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let driver = appState.driverForSelectedDevice() {
            let router = CommandRouter(driver: driver)
            CastingView(viewModel: CastingViewModel(router: router))
        } else {
            VStack(spacing: 12) {
                Text("Sélectionnez un appareil compatible pour caster.")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}
