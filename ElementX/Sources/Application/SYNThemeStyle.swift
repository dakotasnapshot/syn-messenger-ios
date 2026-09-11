//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import Compound
import SwiftUI

struct SYNThemePalette {
    let background: Color
    let surface: Color
    let border: Color
    let accent: Color
    let titleBar: LinearGradient
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let isRetro: Bool
    let usesMonochromeControls: Bool
    
    static func palette(for appearance: AppAppearance, colorMode: SYNColorMode) -> Self {
        let usesDarkColors = colorMode == .dark || (colorMode == .system && appearance == .dark)
        switch appearance {
        case .retro1:
            return .init(background: usesDarkColors ? Color(red: 0.03, green: 0.08, blue: 0.16) : Color(red: 0.93, green: 0.96, blue: 1),
                         surface: usesDarkColors ? Color(red: 0.07, green: 0.14, blue: 0.25) : .white,
                         border: usesDarkColors ? Color(red: 0.45, green: 0.72, blue: 1) : Color(red: 0.10, green: 0.35, blue: 0.72),
                         accent: appearance.accentColor,
                         titleBar: LinearGradient(colors: [Color(red: 0.08, green: 0.42, blue: 0.91), Color(red: 0.35, green: 0.70, blue: 1)], startPoint: .top, endPoint: .bottom),
                         cornerRadius: 10,
                         shadowRadius: 3,
                         isRetro: true,
                         usesMonochromeControls: false)
        case .retro2:
            return .init(background: usesDarkColors ? Color.black : Color(red: 0.91, green: 0.92, blue: 0.88),
                         surface: usesDarkColors ? Color(white: 0.08) : Color(red: 0.98, green: 0.98, blue: 0.94),
                         border: usesDarkColors ? Color(white: 0.72) : Color(red: 0.12, green: 0.12, blue: 0.12),
                         accent: appearance.accentColor,
                         titleBar: LinearGradient(colors: [.black, Color(red: 0.12, green: 0.18, blue: 0.25)], startPoint: .leading, endPoint: .trailing),
                         cornerRadius: 2,
                         shadowRadius: 0,
                         isRetro: true,
                         usesMonochromeControls: false)
        case .dark where colorMode == .system:
            return .init(background: .black, surface: Color(white: 0.08), border: Color.white.opacity(0.55), accent: appearance.accentColor,
                         titleBar: synGradient, cornerRadius: 12, shadowRadius: 0, isRetro: false, usesMonochromeControls: true)
        default:
            return .init(background: usesDarkColors ? Color.black : Color.compound.bgCanvasDefault,
                         surface: usesDarkColors ? Color(white: 0.08) : Color.compound.bgCanvasDefault,
                         border: usesDarkColors ? Color.white.opacity(0.55) : .clear,
                         accent: appearance.accentColor, titleBar: synGradient, cornerRadius: 12, shadowRadius: 0, isRetro: false,
                         usesMonochromeControls: usesDarkColors)
        }
    }
    
    private static var synGradient: LinearGradient {
        LinearGradient(colors: [.blue, Color(red: 0.20, green: 0.08, blue: 0.48), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

private struct SYNThemePaletteKey: EnvironmentKey {
    static let defaultValue = SYNThemePalette.palette(for: .system, colorMode: .system)
}

extension EnvironmentValues {
    var synThemePalette: SYNThemePalette {
        get { self[SYNThemePaletteKey.self] }
        set { self[SYNThemePaletteKey.self] = newValue }
    }
}

extension View {
    func synThemedForm() -> some View {
        modifier(SYNThemedFormModifier())
    }
}

private struct SYNThemedFormModifier: ViewModifier {
    @Environment(\.synThemePalette) private var palette
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(palette.background.ignoresSafeArea())
            .tint(palette.usesMonochromeControls ? .white : palette.accent)
    }
}
