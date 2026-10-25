//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

@testable import ElementX
import SwiftUI
import Testing

struct SYNFoldLayoutTests {
    private let size = CGSize(width: 800, height: 80)
    
    @Test
    func closedAndFullyOpenHaveNoInsets() {
        #expect(SYNFoldLayout.controlInsets(size: size, divisions: []) == EdgeInsets())
    }
    
    @Test
    func bookFoldKeepsComposerInTrailingPane() {
        let insets = SYNFoldLayout.controlInsets(size: size, divisions: [CGRect(x: 380, y: -400, width: 40, height: 800)])
        #expect(insets.leading == 420)
        #expect(insets.trailing == 0)
    }
    
    @Test
    func narrowTrailingPaneUsesLeadingPane() {
        let insets = SYNFoldLayout.controlInsets(size: size, divisions: [CGRect(x: 700, y: -400, width: 40, height: 800)])
        #expect(insets.leading == 0)
        #expect(insets.trailing == 100)
    }
    
    @Test
    func tabletopFoldDoesNotDisplaceBottomComposer() {
        #expect(SYNFoldLayout.controlInsets(size: size, divisions: [CGRect(x: 0, y: -200, width: 800, height: 30)]) == EdgeInsets())
    }
    
    @Test
    func hingeOutsideDetailPaneDoesNotAddInsets() {
        #expect(SYNFoldLayout.controlInsets(size: size, divisions: [CGRect(x: -80, y: -400, width: 40, height: 800)]) == EdgeInsets())
    }
    
    @Test
    func zeroSizeIsSafe() {
        #expect(SYNFoldLayout.controlInsets(size: .zero, divisions: [CGRect(x: 0, y: 0, width: 40, height: 800)]) == EdgeInsets())
    }
}
