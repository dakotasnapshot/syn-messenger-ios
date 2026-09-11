//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

@testable import ElementX
import Foundation
import Testing

struct SYNThemeProfileTests {
    @Test
    func themeProfileRoundTrips() throws {
        let profile = SYNThemeProfile.template
        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(SYNThemeProfile.self, from: data)
        
        #expect(decoded == profile)
    }
    
    @Test
    func builtInThemesRemainCodable() throws {
        for appearance in AppAppearance.allCases {
            let data = try JSONEncoder().encode(appearance)
            #expect(try JSONDecoder().decode(AppAppearance.self, from: data) == appearance)
        }
    }
    
    @Test
    func colorModesRemainCodable() throws {
        for colorMode in SYNColorMode.allCases {
            let data = try JSONEncoder().encode(colorMode)
            #expect(try JSONDecoder().decode(SYNColorMode.self, from: data) == colorMode)
        }
    }
}
