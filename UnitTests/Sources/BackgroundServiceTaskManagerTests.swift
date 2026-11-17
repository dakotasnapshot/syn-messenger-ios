//
// Copyright 2026 Dakota Cole.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import UIKit

struct BackgroundServiceTaskManagerTests {
    private final class Assertions {
        var expirationHandlers: [BackgroundServiceTaskManager.ExpirationHandler] = []
        var ended: [UIBackgroundTaskIdentifier] = []
        var refuseAssertion = false
        
        lazy var manager = BackgroundServiceTaskManager(begin: { [self] handler in
            expirationHandlers.append(handler)
            return refuseAssertion ? .invalid : UIBackgroundTaskIdentifier(rawValue: expirationHandlers.count)
        }, end: { [self] identifier in
            ended.append(identifier)
        })
    }
    
    @Test
    func shutdownKeepsProtectionUntilCompletion() async {
        let assertions = Assertions()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = assertions.manager.run {
            for await _ in stream { }
        }
        
        #expect(assertions.ended.isEmpty)
        continuation.finish()
        await task.value
        #expect(assertions.ended.map(\.rawValue) == [1])
    }
    
    @Test
    func olderCompletionCannotEndNewerProtection() async {
        let assertions = Assertions()
        let (firstStream, firstContinuation) = AsyncStream<Void>.makeStream()
        let (secondStream, secondContinuation) = AsyncStream<Void>.makeStream()
        let first = assertions.manager.run {
            for await _ in firstStream { }
        }
        let second = assertions.manager.run {
            for await _ in secondStream { }
        }
        
        #expect(assertions.expirationHandlers.count == 2)
        firstContinuation.finish()
        await first.value
        #expect(assertions.ended.map(\.rawValue) == [1])
        secondContinuation.finish()
        await second.value
        #expect(assertions.ended.map(\.rawValue) == [1, 2])
    }
    
    @Test
    func expirationEndsOnlyItsOwnAssertionOnce() async {
        let assertions = Assertions()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let first = assertions.manager.run {
            for await _ in stream { }
        }
        assertions.expirationHandlers[0]()
        assertions.expirationHandlers[0]()
        #expect(assertions.ended.map(\.rawValue) == [1])
        
        let second = assertions.manager.run { }
        continuation.finish()
        await first.value
        await second.value
        #expect(assertions.ended.map(\.rawValue) == [1, 2])
    }
    
    @Test
    func invalidAssertionStillRunsShutdownWithoutEndingInvalidIdentifier() async {
        let assertions = Assertions()
        assertions.refuseAssertion = true
        var completed = false
        await assertions.manager.run { completed = true }.value
        #expect(completed)
        #expect(assertions.ended.isEmpty)
    }
}
