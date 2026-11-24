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
    
    func testSidebarCompressesAndExpandsWithoutLosingDraft() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": UITestsScreenIdentifier.userSessionSpacesFlow.rawValue]
        app.launch()
        let room = app.buttons[A11yIdentifiers.homeScreen.roomName("Foundation 🔭🪐🌌")]
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        let initialList = app.scrollViews["SYN.ConversationList"]
        XCTAssertTrue(initialList.exists)
        try XCTSkipIf(initialList.frame.width > app.frame.width * 0.7, "Avatar rail applies to the split-view sidebar, not compact navigation.")
        let search = app.textFields["SYN.SidebarSearch"]
        XCTAssertTrue(search.isHittable)
        search.tap()
        search.typeText("Foundation")
        XCTAssertEqual(search.value as? String, "Foundation")
        search.typeText(XCUIKeyboardKey.return.rawValue)
        let unrelatedRoom = app.buttons[A11yIdentifiers.homeScreen.roomName("Unknown")]
        let filtered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !unrelatedRoom.exists }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [filtered], timeout: 5), .completed,
                       "Submitting a search must keep its results filtered after the keyboard resigns.")
        XCTAssertEqual(search.value as? String, "Foundation")
        let clearSearch = app.buttons["Clear"].firstMatch
        XCTAssertTrue(clearSearch.isHittable)
        clearSearch.tap()
        XCTAssertFalse(clearSearch.exists)
        XCTAssertTrue(unrelatedRoom.waitForExistence(timeout: 5), "Clearing search restores the ordinary room list.")
        search.tap()
        search.typeText("Foundation")
        search.typeText(XCUIKeyboardKey.return.rawValue)
        XCTAssertTrue(room.isHittable)
        room.tap()
        let showSidebar = app.buttons["Show Sidebar"]
        if showSidebar.waitForExistence(timeout: 2), !room.isHittable {
            showSidebar.tap()
        }
        let list = app.scrollViews["SYN.ConversationList"]
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        let composer = app.textViews[A11yIdentifiers.roomScreen.messageComposer]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        composer.tap()
        composer.typeText("Sidebar draft stays intact")
        capture(name: "Expanded sidebar with draft")
        dragSidebar(in: app, list: list, toWidth: 96)
        let actions = app.buttons["SYN.SidebarActions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 5), "Narrowing the sidebar must expose its consolidated actions menu.")
        XCTAssertLessThan(list.frame.width, 170)
        XCTAssertTrue(unrelatedRoom.waitForExistence(timeout: 5), "Collapsing the search header cancels its query and restores all avatars.")
        XCTAssertEqual(composer.value as? String, "Sidebar draft stays intact")
        XCTAssertTrue(room.isHittable, "The selected conversation avatar remains a usable target.")
        XCTAssertGreaterThanOrEqual(room.frame.minY, actions.frame.maxY - 1, "The first avatar must sit fully below the collapsed toolbar.")
        XCTAssertGreaterThanOrEqual(room.frame.minY, list.frame.minY - 1)
        XCTAssertGreaterThanOrEqual(room.frame.height, 64, "The avatar row must retain enough height to show the whole circle.")
        XCTAssertLessThanOrEqual(room.frame.maxY, list.frame.maxY - 32)
        let firstRailRoom = app.buttons[A11yIdentifiers.homeScreen.roomName("First space")]
        XCTAssertTrue(firstRailRoom.exists)
        XCTAssertGreaterThanOrEqual(firstRailRoom.frame.minY, actions.frame.maxY - 1)
        XCTAssertGreaterThanOrEqual(firstRailRoom.frame.minY, list.frame.minY - 1)
        XCTAssertGreaterThanOrEqual(firstRailRoom.frame.height, 64)
        capture(name: "Collapsed avatar rail with draft")
        actions.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "Settings").firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "Start chat").firstMatch.exists)
        capture(name: "Avatar rail actions dropdown")
        let navigation = app.descendants(matching: .any).matching(identifier: "SYN.SidebarNavigation").firstMatch
        XCTAssertTrue(navigation.exists)
        navigation.tap()
        app.descendants(matching: .any).matching(identifier: "Spaces").firstMatch.tap()
        let foundationSpace = app.buttons[A11yIdentifiers.spacesScreen.spaceRoomName("The Foundation")]
        XCTAssertTrue(foundationSpace.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(foundationSpace.frame.width, 200, "Spaces must retain a readable primary column rather than inherit the avatar rail width.")
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "SYN.SidebarResizeHandle").firstMatch.exists)
        capture(name: "Spaces keeps its normal readable sidebar")
        let spacesNavigation = app.descendants(matching: .any).matching(identifier: "SYN.SidebarNavigation").firstMatch
        XCTAssertTrue(spacesNavigation.exists)
        spacesNavigation.tap()
        app.descendants(matching: .any).matching(identifier: "Chats").firstMatch.tap()
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        XCTAssertEqual(composer.value as? String, "Sidebar draft stays intact")
        dragSidebar(in: app, list: list, toWidth: 320)
        let expanded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            list.frame.width > 250 && !actions.exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expanded], timeout: 5), .completed)
        XCTAssertEqual(composer.value as? String, "Sidebar draft stays intact")
        XCTAssertTrue(app.buttons[A11yIdentifiers.homeScreen.startChat].isHittable)
        XCTAssertTrue(room.isHittable)
        capture(name: "Restored conversation previews and draft")
        let toggleSidebar = app.buttons["SYN.ToggleConversationSidebar"]
        XCTAssertTrue(toggleSidebar.isHittable)
        toggleSidebar.tap()
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !list.exists }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 5), .completed)
        XCTAssertEqual(composer.value as? String, "Sidebar draft stays intact")
        capture(name: "Hidden sidebar retains conversation draft")
        XCTAssertTrue(toggleSidebar.isHittable)
        toggleSidebar.tap()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertTrue(room.isHittable)
        XCTAssertEqual(composer.value as? String, "Sidebar draft stays intact")
        capture(name: "Restored sidebar retains conversation draft")
    }
    
    func testPartialMessageTextCanBeCopiedIntoComposer() {
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": UITestsScreenIdentifier.userSessionScreen.rawValue]
        app.launch()
        let room = app.buttons[A11yIdentifiers.homeScreen.roomName("Foundation 🔭🪐🌌")]
        XCTAssertTrue(room.waitForExistence(timeout: 10))
        room.tap()
        let composer = app.textViews[A11yIdentifiers.roomScreen.messageComposer]
        XCTAssertTrue(composer.waitForExistence(timeout: 5))
        let body = "Syndicate selectable words stay private"
        composer.tap()
        composer.typeText(body)
        app.buttons[A11yIdentifiers.roomScreen.sendButton].tap()
        let message = app.textViews.matching(NSPredicate(format: "value CONTAINS %@ AND identifier != %@", body, A11yIdentifiers.roomScreen.messageComposer)).firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        let visibleMessage = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            message.isHittable && message.frame.width > 0 && message.frame.height > 0
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [visibleMessage], timeout: 5), .completed,
                       "Native message text must expose its actual rendered bounds, not an accessibility-only zero-frame copy.")
        capture(name: "Visible synthetic message before selection")
        // The native text-view centre can be whitespace when the last line is short.
        message.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.25)).doubleTap()
        let copy = app.menuItems["Copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: 5), "Double-tapping a word must expose native text selection, not the whole-message action sheet.")
        capture(name: "Native message word selection and handles")
        copy.tap()
        composer.press(forDuration: 1)
        let paste = app.menuItems["Paste"]
        XCTAssertTrue(paste.waitForExistence(timeout: 5))
        paste.tap()
        let pasted = composer.value as? String ?? ""
        XCTAssertFalse(pasted.isEmpty)
        XCTAssertNotEqual(pasted, body, "Copy must use the selected word rather than the entire message.")
        XCTAssertTrue(body.contains(pasted), "The pasted selection must come from the synthetic message.")
        capture(name: "Copied message subset in composer")
    }
    
    func testFocusedMessageHighlightAppearance() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        defer { try? client.stop() }
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTS_SCREEN": UITestsScreenIdentifier.roomLayoutHighlight.rawValue]
        app.launch()
        await client.waitForApp()
        try client.send(.timeline(.focusOnEvent("$5")))
        var iterator = client.signals.values.makeAsyncIterator()
        while let signal = await iterator.next(isolation: #isolation), signal != .success { }
        try await Task.sleep(for: .seconds(2))
        XCTAssertTrue(app.textViews[A11yIdentifiers.roomScreen.messageComposer].exists)
        capture(name: "Purple blue focused message highlight")
    }
    
    private func dragSidebar(in app: XCUIApplication, list: XCUIElement, toWidth: CGFloat) {
        let handle = app.descendants(matching: .any)["SYN.SidebarResizeHandle"].firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        XCTAssertTrue(handle.isHittable)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = origin.withOffset(CGVector(dx: list.frame.minX + toWidth, dy: handle.frame.midY))
        start.press(forDuration: 0.2, thenDragTo: end)
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
        for _ in 0..<32 {
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
