//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@MainActor
final class SYNAdaptiveLayoutUITests: XCTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }
    
    func testSignInRemainsReachableAfterRotation() {
        let app = launch(.authenticationFlow)
        let signIn = app.buttons[A11yIdentifiers.authenticationStartScreen.signIn]
        XCTAssertTrue(signIn.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        waitForLandscape(app)
        XCTAssertTrue(signIn.isHittable)
        capture(app, name: "Onboarding landscape")
        signIn.tap()
        let server = app.textFields[A11yIdentifiers.changeServerScreen.server]
        XCTAssertTrue(server.waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
        waitForPortrait(app)
        XCTAssertTrue(server.isHittable)
        capture(app, name: "Server selection portrait")
    }
    
    func testComposerDraftSurvivesRotation() {
        let app = launch(.roomPlainNoAvatar)
        let composer = app.textViews.firstMatch
        XCTAssertTrue(composer.waitForExistence(timeout: 10))
        composer.tap()
        composer.typeText("Synthetic resize draft")
        XCUIDevice.shared.orientation = .landscapeLeft
        waitForLandscape(app)
        XCTAssertTrue(composer.isHittable)
        XCTAssertEqual(composer.value as? String, "Synthetic resize draft")
        capture(app, name: "Composer landscape with draft")
        XCUIDevice.shared.orientation = .portrait
        waitForPortrait(app)
        XCTAssertTrue(composer.isHittable)
        XCTAssertEqual(composer.value as? String, "Synthetic resize draft")
    }
    
    private func launch(_ screen: UITestsScreenIdentifier) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": screen.rawValue]
        app.launch()
        return app
    }
    
    private func waitForLandscape(_ app: XCUIApplication) {
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 5), .completed,
                       "The scene must actually resize; a rotation request alone is not layout coverage.")
    }
    
    private func waitForPortrait(_ app: XCUIApplication) {
        let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.height > app.frame.width
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portrait], timeout: 5), .completed)
    }
    
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
