//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

/// SwiftUI already avoids docked keyboards. Track only the remaining bottom obstruction.
struct SYNComposerKeyboardClearance: ViewModifier {
    @State private var clearance: CGFloat = 0
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, clearance)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .overlay {
                    KeyboardClearanceReader(clearance: $clearance)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
        }
    }
}

private struct KeyboardClearanceReader: UIViewRepresentable {
    @Binding var clearance: CGFloat
    
    func makeUIView(context: Context) -> KeyboardClearanceView {
        let view = KeyboardClearanceView()
        view.onClearanceChange = { value in
            DispatchQueue.main.async {
                if abs(clearance - value) > 0.5 {
                    clearance = value
                }
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: KeyboardClearanceView, context: Context) { }
}

private final class KeyboardClearanceView: UIView {
    var onClearanceChange: ((CGFloat) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        keyboardLayoutGuide.followsUndockedKeyboard = true
        keyboardLayoutGuide.usesBottomSafeArea = false
        let marker = UIView()
        marker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(marker)
        NSLayoutConstraint.activate([
            marker.topAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            marker.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.bottomAnchor),
            marker.leadingAnchor.constraint(equalTo: leadingAnchor),
            marker.widthAnchor.constraint(equalToConstant: 0)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onClearanceChange?(SYNKeyboardClearance.bottomClearance(in: bounds, keyboard: keyboardLayoutGuide.layoutFrame))
    }
}

nonisolated enum SYNKeyboardClearance {
    static func bottomClearance(in bounds: CGRect, keyboard: CGRect) -> CGFloat {
        // A floating keyboard high in the conversation must not push the whole composer off screen.
        guard keyboard.height > 0, keyboard.maxY >= bounds.maxY - 160,
              keyboard.maxX > bounds.minX, keyboard.minX < bounds.maxX else { return 0 }
        return max(0, bounds.maxY - max(bounds.minY, keyboard.minY))
    }
}
