//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Used to specify the user's app specific appearance preference
nonisolated enum AppAppearance: String, CaseIterable, Codable {
    case system
    case dark
    case light
    case retro1
    case retro2
    case custom
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light, .retro1, .retro2:
            return .light
        case .dark:
            return .dark
        case .system, .custom:
            return .unspecified
        }
    }
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .dark: .dark
        case .light, .retro1, .retro2: .light
        case .system, .custom: nil
        }
    }
    
    var accentColor: Color {
        switch self {
        case .retro1: Color(red: 0.05, green: 0.42, blue: 0.78)
        case .retro2: Color(red: 0.08, green: 0.18, blue: 0.35)
        default: Color(red: 0.43, green: 0.25, blue: 0.94)
        }
    }
    
    var fontDesign: Font.Design {
        switch self {
        case .retro1: .rounded
        case .retro2: .monospaced
        default: .default
        }
    }
}

nonisolated enum SYNColorMode: String, CaseIterable, Codable {
    case system
    case light
    case dark
    
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}
