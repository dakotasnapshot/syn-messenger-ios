//
// Copyright 2026 Hawthorn LLC
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

nonisolated enum GiphyConfiguration {
    static let apiKey: String? = {
        guard let url = Bundle.main.url(forResource: "SyndicateServices", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let configuration = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
              let key = configuration["GiphyAPIKey"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty else { return nil }
        return key
    }()
}
