//
// Copyright 2026 SYN Messenger contributors.
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@MainActor
final class SYNConversationListUITests: XCTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }
    
    func testLastConversationRemainsReachable() {
        checkLastConversation(landscape: false)
    }
    
    func testLastConversationRemainsReachableInLandscape() {
        checkLastConversation(landscape: true)
    }
    
    private func checkLastConversation(landscape: Bool) {
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": UITestsScreenIdentifier.userSessionScreen.rawValue,
                                 "UI_TESTS_LONG_ROOM_LIST": "1"]
        app.launch()
        let resized = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            landscape ? app.frame.width > app.frame.height : app.frame.height > app.frame.width
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [resized], timeout: 5), .completed)
        let firstRoom = app.buttons[A11yIdentifiers.homeScreen.roomName("Foundation 🔭🪐🌌")]
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10))
        let list = app.scrollViews["SYN.ConversationList"]
        XCTAssertTrue(list.exists)
        let hasSidebar = list.frame.width < app.frame.width * 0.7
        let fadeClearance: CGFloat = hasSidebar ? 32 : 0
        if hasSidebar {
            XCTAssertGreaterThan(list.frame.maxY, app.frame.maxY - 45,
                                 "The iPad sidebar must not leave a navigation-bar-sized blank strip below the list.")
        }
        capture(name: "Conversation list top")
        let lastRoom = app.buttons[A11yIdentifiers.homeScreen.roomName("Conversation 24")]
        for _ in 0..<12 {
            if lastRoom.exists, lastRoom.isHittable, lastRoom.frame.maxY < list.frame.maxY - fadeClearance {
                break
            }
            list.swipeUp()
        }
        XCTAssertTrue(lastRoom.isHittable)
        XCTAssertLessThan(lastRoom.frame.maxY, list.frame.maxY - fadeClearance,
                          "The final row must scroll completely above the decorative fade.")
        capture(name: "Conversation list last row above fade")
        lastRoom.tap()
        XCTAssertTrue(app.textViews[A11yIdentifiers.roomScreen.messageComposer].waitForExistence(timeout: 10))
        capture(name: "Selected conversation rounded sidebar")
    }
    
    private func capture(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
