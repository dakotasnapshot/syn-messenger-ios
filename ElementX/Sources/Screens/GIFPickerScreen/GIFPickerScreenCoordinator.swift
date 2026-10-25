//
// Copyright 2026 Hawthorn LLC
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import GiphyUISDK
import SwiftUI

enum GIFPickerScreenCoordinatorAction {
    case selectedGIF(URL)
    case cancel
}

final class GIFPickerScreenCoordinator: CoordinatorProtocol {
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let callback: (GIFPickerScreenCoordinatorAction) -> Void
    
    init(userIndicatorController: UserIndicatorControllerProtocol,
         callback: @escaping (GIFPickerScreenCoordinatorAction) -> Void) {
        self.userIndicatorController = userIndicatorController
        self.callback = callback
    }
    
    func toPresentable() -> AnyView {
        AnyView(GIFPickerScreen { [weak self] action in
            self?.handle(action)
        })
    }
    
    private func handle(_ action: GIFPickerScreenAction) {
        switch action {
        case .cancel:
            callback(.cancel)
        case .selected(let remoteURL):
            Task { @MainActor in
                do {
                    let localURL = try await downloadGIF(from: remoteURL)
                    callback(.selectedGIF(localURL))
                } catch {
                    MXLog.error("Failed downloading a selected GIF: \(error)")
                    userIndicatorController.submitIndicator(UserIndicator(title: UntranslatedL10n.screenGifPickerDownloadError))
                }
            }
        }
    }
    
    private func downloadGIF(from remoteURL: URL) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("syndicate-gif-\(UUID().uuidString)")
            .appendingPathExtension("gif")
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }
}

private enum GIFPickerScreenAction {
    case selected(URL)
    case cancel
}

private struct GIFPickerScreen: UIViewControllerRepresentable {
    let callback: (GIFPickerScreenAction) -> Void
    
    func makeUIViewController(context: Context) -> GiphyViewController {
        let controller = GiphyViewController()
        controller.delegate = context.coordinator
        controller.mediaTypeConfig = [.gifs, .recents]
        controller.showConfirmationScreen = true
        controller.shouldLocalizeSearch = true
        controller.rating = .ratedPG13
        controller.theme = GPHTheme(type: .automatic)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: GiphyViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(callback: callback)
    }
    
    final class Coordinator: NSObject, GiphyDelegate {
        private let callback: (GIFPickerScreenAction) -> Void
        
        init(callback: @escaping (GIFPickerScreenAction) -> Void) {
            self.callback = callback
        }
        
        func didSelectMedia(giphyViewController: GiphyViewController, media: GPHMedia) {
            guard let urlString = media.url(rendition: .original, fileType: .gif),
                  let url = URL(string: urlString) else {
                return
            }
            callback(.selected(url))
        }
        
        func didDismiss(controller: GiphyViewController?) {
            callback(.cancel)
        }
    }
}
