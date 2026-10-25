//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

enum SYNFoldLayout {
    /// Coordinates follow SwiftUI's logical layout direction, including RTL.
    nonisolated static func controlInsets(size: CGSize, divisions: [CGRect]) -> EdgeInsets {
        let bounds = CGRect(origin: .zero, size: size)
        guard size.width > 0, size.height > 0,
              let division = divisions.first(where: { frame in
                  frame.height > frame.width && frame.intersects(bounds)
              }) else {
            return EdgeInsets()
        }
        
        let leadingWidth = max(0, division.minX)
        let trailingWidth = max(0, size.width - division.maxX)
        // Prefer the trailing pane, but don't strand controls in a narrow sliver.
        if trailingWidth >= min(240, leadingWidth) {
            return EdgeInsets(top: 0, leading: min(size.width, max(0, division.maxX)), bottom: 0, trailing: 0)
        }
        return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: min(size.width, max(0, size.width - division.minX)))
    }
}

private struct SYNFoldAwareControls: ViewModifier {
    @State private var insets = EdgeInsets()
    
    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content
                .padding(insets)
                .onGeometryChange(for: EdgeInsets.self) { geometry in
                    SYNFoldLayout.controlInsets(size: geometry.size,
                                                divisions: geometry.reservedRegions(kind: .division).map(\.frame))
                } action: { insets = $0 }
        } else {
            content
        }
    }
}

extension View {
    /// Keep grouped controls off a vertical fold; bottom insets already handle tabletop controls.
    func synFoldAwareControls() -> some View {
        modifier(SYNFoldAwareControls())
    }
}
