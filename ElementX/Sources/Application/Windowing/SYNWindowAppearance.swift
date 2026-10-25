//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

enum SYNWindowAppearance {
    static func apply(to window: UIWindow, colorMode: SYNColorMode, refreshKeyboard: Bool = false) {
        window.overrideUserInterfaceStyle = colorMode.interfaceStyle
        updateInputs(in: window, refreshKeyboard: refreshKeyboard)
    }
    
    static func keyboardAppearance(for interfaceStyle: UIUserInterfaceStyle) -> UIKeyboardAppearance {
        interfaceStyle == .dark ? .dark : .light
    }
    
    private static func updateInputs(in view: UIView, refreshKeyboard: Bool) {
        // Window overrides propagate lazily; resolve traits before choosing the keyboard style.
        view.updateTraitsIfNeeded()
        let keyboardAppearance = keyboardAppearance(for: view.traitCollection.userInterfaceStyle)
        let previousAppearance: UIKeyboardAppearance?
        if let textView = view as? UITextView {
            previousAppearance = textView.keyboardAppearance
            textView.keyboardAppearance = keyboardAppearance
        } else if let textField = view as? UITextField {
            previousAppearance = textField.keyboardAppearance
            textField.keyboardAppearance = keyboardAppearance
        } else {
            previousAppearance = nil
        }
        // iOS can restore the previous app's keyboard when our responder survives app switching.
        if let previousAppearance, view.isFirstResponder, previousAppearance != keyboardAppearance || refreshKeyboard {
            view.reloadInputViews()
        }
        for subview in view.subviews {
            updateInputs(in: subview, refreshKeyboard: refreshKeyboard)
        }
    }
}
