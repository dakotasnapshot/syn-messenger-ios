//
// Copyright 2026 The Syndicate Contributors
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import LinkPresentation
import UniformTypeIdentifiers

@MainActor
protocol NotificationLinkPreviewProviderProtocol: Sendable {
    func imageData(for url: URL) async -> Data?
}

@MainActor
struct NotificationLinkPreviewProvider: NotificationLinkPreviewProviderProtocol {
    func imageData(for url: URL) async -> Data? {
        guard let metadata = try? await LPMetadataProvider().startFetchingMetadata(for: url),
              let provider = metadata.imageProvider ?? metadata.iconProvider else {
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                guard let data,
                      let image = UIImage(data: data),
                      let thumbnail = image.preparingThumbnail(of: .init(width: 1200, height: 1200)),
                      let jpegData = thumbnail.jpegData(compressionQuality: 0.8),
                      jpegData.count <= 10_000_000 else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: jpegData)
            }
        }
    }
}
