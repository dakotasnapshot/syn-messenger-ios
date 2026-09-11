//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct SYNThemeProfile: Codable, Equatable, Sendable {
    let formatVersion: Int
    let name: String
    let preferredAppearance: PreferredAppearance
    let accentHex: String
    let backgroundHex: String
    let fontStyle: FontStyle
    
    enum PreferredAppearance: String, Codable, Sendable {
        case system, light, dark
    }
    
    enum FontStyle: String, Codable, Sendable {
        case system, rounded, monospaced
    }
    
    static let template = SYNThemeProfile(formatVersion: 1,
                                          name: "My Theme",
                                          preferredAppearance: .system,
                                          accentHex: "#6D40EF",
                                          backgroundHex: "#11102B",
                                          fontStyle: .system)
    
    var accentColor: Color {
        Color(hex: accentHex) ?? AppAppearance.custom.accentColor
    }
    
    var backgroundColor: Color {
        Color(hex: backgroundHex) ?? .clear
    }
    
    var preferredColorScheme: ColorScheme? {
        switch preferredAppearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
    
    var fontDesign: Font.Design {
        switch fontStyle {
        case .system: .default
        case .rounded: .rounded
        case .monospaced: .monospaced
        }
    }
}

struct SYNThemeDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.json]
    }
    
    var profile: SYNThemeProfile
    
    init(profile: SYNThemeProfile = .template) {
        self.profile = profile
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        profile = try JSONDecoder().decode(SYNThemeProfile.self, from: data)
        guard profile.formatVersion == 1 else { throw CocoaError(.fileReadUnsupportedScheme) }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try FileWrapper(regularFileWithContents: encoder.encode(profile))
    }
}

private nonisolated extension Color {
    init?(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = UInt64(value, radix: 16) else { return nil }
        self.init(red: Double((rgb >> 16) & 0xFF) / 255,
                  green: Double((rgb >> 8) & 0xFF) / 255,
                  blue: Double(rgb & 0xFF) / 255)
    }
}
