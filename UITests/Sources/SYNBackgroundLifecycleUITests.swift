//
// Copyright 2026 Dakota Cole.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
final class SYNBackgroundLifecycleUITests: XCTestCase {
    func testProductionCoordinatorSurvivesRepeatedBackgroundTransitions() {
        let app = XCUIApplication()
        // No UI_TESTS_SCREEN: exercise the real lifecycle coordinator, not a screen fixture.
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 20))
        
        for _ in 0..<5 {
            XCUIDevice.shared.press(.home)
            let backgrounded = NSPredicate { _, _ in
                app.state == .runningBackground || app.state == .runningBackgroundSuspended
            }
            expectation(for: backgrounded, evaluatedWith: app)
            waitForExpectations(timeout: 10)
            app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
            XCTAssertTrue(app.windows.firstMatch.exists)
        }
        
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Lifecycle smoke after five background transitions"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
