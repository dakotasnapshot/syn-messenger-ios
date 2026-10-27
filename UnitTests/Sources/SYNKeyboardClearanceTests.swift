//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

@testable import ElementX
import SwiftUI
import Testing

struct SYNKeyboardClearanceTests {
    private let bounds = CGRect(x: 0, y: 0, width: 900, height: 700)
    
    @Test
    func floatingAccessoryReservesSpace() {
        #expect(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: CGRect(x: 220, y: 640, width: 460, height: 44)) == 60)
    }
    
    @Test
    func dockedKeyboardAlreadyAvoidedBySwiftUIIsNotCountedTwice() {
        #expect(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: CGRect(x: 0, y: 700, width: 900, height: 300)) == 0)
    }
    
    @Test
    func hiddenOrUnrelatedKeyboardDoesNotMoveComposer() {
        #expect(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: .zero) == 0)
        #expect(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: CGRect(x: 1000, y: 640, width: 460, height: 44)) == 0)
        #expect(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: CGRect(x: 200, y: 150, width: 320, height: 240)) == 0)
    }
}
