//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI

struct SYNThemeHost<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    let appSettings: AppSettings
    @ViewBuilder let content: Content
    @State private var appearance: AppAppearance
    @State private var colorMode: SYNColorMode
    @State private var customProfile: SYNThemeProfile?
    
    init(appSettings: AppSettings, @ViewBuilder content: () -> Content) {
        self.appSettings = appSettings
        self.content = content()
        _appearance = State(initialValue: appSettings.appAppearance)
        _colorMode = State(initialValue: appSettings.synColorMode)
        _customProfile = State(initialValue: appSettings.customThemeData.flatMap { try? JSONDecoder().decode(SYNThemeProfile.self, from: $0) })
    }
    
    var body: some View {
        let resolvedColorMode: SYNColorMode = colorMode == .system ? (systemColorScheme == .dark ? .dark : .light) : colorMode
        let palette = SYNThemePalette.palette(for: appearance, colorMode: resolvedColorMode)
        content
            .preferredColorScheme(colorMode.preferredColorScheme)
            .tint(palette.usesMonochromeControls ? Color(white: 0.82) : customProfile?.accentColor ?? appearance.accentColor)
            .fontDesign(customProfile?.fontDesign ?? appearance.fontDesign)
            .environment(\.synThemePalette, palette)
            .onReceive(appSettings.appAppearancePublisher) {
                appearance = $0
                customProfile = appSettings.customThemeData.flatMap { try? JSONDecoder().decode(SYNThemeProfile.self, from: $0) }
            }
            .onReceive(appSettings.synColorModePublisher) { colorMode = $0 }
    }
}
