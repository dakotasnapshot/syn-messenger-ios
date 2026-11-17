//
// Copyright 2026 Dakota Cole.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Keeps each database shutdown protected until its own completion or system expiration.
final class BackgroundServiceTaskManager {
    typealias ExpirationHandler = @MainActor @Sendable () -> Void
    
    private let begin: (@escaping ExpirationHandler) -> UIBackgroundTaskIdentifier
    private let end: (UIBackgroundTaskIdentifier) -> Void
    private var assertions: [UUID: UIBackgroundTaskIdentifier] = [:]
    
    init(begin: @escaping (@escaping ExpirationHandler) -> UIBackgroundTaskIdentifier,
         end: @escaping (UIBackgroundTaskIdentifier) -> Void) {
        self.begin = begin
        self.end = end
    }
    
    @discardableResult
    func run(operation: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let token = UUID()
        let identifier = begin { [weak self] in
            self?.finish(token)
        }
        if identifier != .invalid {
            assertions[token] = identifier
        }
        
        // Foregrounding must not cancel a database close or release its assertion early.
        return Task {
            await operation()
            finish(token)
        }
    }
    
    private func finish(_ token: UUID) {
        guard let identifier = assertions.removeValue(forKey: token) else { return }
        end(identifier)
    }
}
