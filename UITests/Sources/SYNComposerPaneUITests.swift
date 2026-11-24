//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@MainActor
final class SYNComposerPaneUITests: XCTestCase {
    func testComposerFitsConversationPane() {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": UITestsScreenIdentifier.userSessionScreen.rawValue]
        app.launch()
        XCUIDevice.shared.orientation = .portrait
        let room = app.buttons[A11yIdentifiers.homeScreen.roomName("Foundation 🔭🪐🌌")]
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        room.tap()
        let showSidebar = app.buttons["Show Sidebar"]
        if showSidebar.waitForExistence(timeout: 2), !room.isHittable {
            showSidebar.tap()
        }
        let composer = app.textViews[A11yIdentifiers.roomScreen.messageComposer]
        XCTAssertTrue(composer.waitForExistence(timeout: 10))
        let attachments = app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions]
        XCTAssertTrue(attachments.isHittable, "The leading attachment control must not be hidden behind the sidebar.")
        composer.tap()
        composer.typeText("1234567891011121314151617181920212223")
        XCTAssertEqual(composer.value as? String, "1234567891011121314151617181920212223")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Conversation pane numeric draft"
        attachment.lifetime = .keepAlways
        add(attachment)
        let bounds = XCTAttachment(string: "composer=\(composer.frame) room=\(room.frame) app=\(app.frame)")
        bounds.name = "Conversation pane bounds"
        bounds.lifetime = .keepAlways
        add(bounds)
        if room.exists, room.isHittable, room.frame.maxX < app.frame.midX {
            XCTAssertGreaterThanOrEqual(composer.frame.minX, room.frame.maxX,
                                        "Composer must begin inside the conversation, not behind its sidebar.")
        }
        XCTAssertGreaterThanOrEqual(composer.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(composer.frame.maxX, app.frame.maxX)
        XCTAssertTrue(app.buttons[A11yIdentifiers.roomScreen.sendButton].isHittable)
        composer.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertEqual(composer.value as? String, "123456789101112131415161718192021222")
        composer.typeText(String(repeating: " wrapped draft", count: 12))
        XCTAssertTrue(attachments.isHittable)
        XCTAssertTrue(app.buttons[A11yIdentifiers.roomScreen.sendButton].isHittable)
        XCTAssertGreaterThan(composer.frame.height, 22)
        let wrapped = XCTAttachment(screenshot: app.screenshot())
        wrapped.name = "Conversation pane wrapped draft"
        wrapped.lifetime = .keepAlways
        add(wrapped)
    }
}
