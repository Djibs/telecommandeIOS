// File: Core/Casting/CastingViewModel.swift

import Foundation
import PhotosUI
import SwiftUI
import Combine

@MainActor
public final class CastingViewModel: ObservableObject {
    @Published public var selectedItem: PhotosPickerItem?
    @Published public private(set) var errorMessage: String?

    private let router: CommandRouting

    public init(router: CommandRouting) {
        self.router = router
    }

    public func castSelectedItem() async {
        guard let selectedItem else { return }
        do {
            let data = try await selectedItem.loadTransferable(type: Data.self)
            guard let data else { return }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try data.write(to: tempURL)
            let type: MediaType = selectedItem.supportedContentTypes.contains(where: { $0.conforms(to: .image) }) ? .photo : .video
            try await router.castMedia(url: tempURL, type: type)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
