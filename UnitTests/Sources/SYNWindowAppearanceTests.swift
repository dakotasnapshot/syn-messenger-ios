//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

@testable import ElementX
import SwiftUI
import Testing

struct SYNWindowAppearanceTests {
    @Test
    func explicitModesUpdateNestedInputs() {
        let window = UIWindow()
        let container = UIView()
        let field = UITextField()
        let editor = UITextView()
        window.addSubview(container)
        container.addSubview(field)
        container.addSubview(editor)
        
        SYNWindowAppearance.apply(to: window, colorMode: .dark)
        #expect(window.overrideUserInterfaceStyle == .dark)
        #expect(field.keyboardAppearance == .dark)
        #expect(editor.keyboardAppearance == .dark)
        
        SYNWindowAppearance.apply(to: window, colorMode: .light)
        #expect(window.overrideUserInterfaceStyle == .light)
        #expect(field.keyboardAppearance == .light)
        #expect(editor.keyboardAppearance == .light)
    }
    
    @Test
    func foregroundRefreshPreservesDraft() {
        let window = UIWindow()
        let field = KeyboardRefreshSpy()
        field.text = "Unsent draft"
        window.addSubview(field)
        SYNWindowAppearance.apply(to: window, colorMode: .dark)
        let initialReloadCount = field.reloadCount
        
        SYNWindowAppearance.apply(to: window, colorMode: .dark)
        #expect(field.reloadCount == initialReloadCount)
        SYNWindowAppearance.apply(to: window, colorMode: .dark, refreshKeyboard: true)
        #expect(field.reloadCount == initialReloadCount + 1)
        #expect(field.text == "Unsent draft")
        #expect(field.keyboardAppearance == .dark)
    }
    
    @Test
    func systemModeClearsExplicitOverride() {
        let window = UIWindow()
        SYNWindowAppearance.apply(to: window, colorMode: .dark)
        SYNWindowAppearance.apply(to: window, colorMode: .system)
        #expect(window.overrideUserInterfaceStyle == .unspecified)
    }
    
    @Test
    func systemModeTracksTraitChanges() {
        let window = UIWindow()
        let field = UITextField()
        window.addSubview(field)
        window.traitOverrides.userInterfaceStyle = .dark
        SYNWindowAppearance.apply(to: window, colorMode: .system)
        #expect(field.keyboardAppearance == .dark)
        window.traitOverrides.userInterfaceStyle = .light
        SYNWindowAppearance.apply(to: window, colorMode: .system)
        #expect(field.keyboardAppearance == .light)
    }
    
    @Test
    func keyboardTracksResolvedInterfaceStyle() {
        #expect(SYNWindowAppearance.keyboardAppearance(for: .dark) == .dark)
        #expect(SYNWindowAppearance.keyboardAppearance(for: .light) == .light)
    }
}

private class KeyboardRefreshSpy: UITextField {
    var reloadCount = 0
    override var isFirstResponder: Bool {
        true
    }
    
    override func reloadInputViews() {
        reloadCount += 1
    }
}
