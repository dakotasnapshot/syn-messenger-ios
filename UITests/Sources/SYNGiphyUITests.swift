//
// Copyright 2026 Hawthorn LLC
//
// SPDX-License-Identifier: AGPL-3.0-only
//

import XCTest

@MainActor
final class SYNGiphyUITests: XCTestCase {
    func testGIFPickerAvailableAndSearchable() {
        let app = XCUIApplication()
        app.launchEnvironment["UI_TESTS_SCREEN"] = UITestsScreenIdentifier.appStoreHome.rawValue
        app.launchEnvironment["UI_TESTS_DISABLE_TIMELINE_ACCESSIBILITY"] = "1"
        app.launch()
        let room = app.buttons[A11yIdentifiers.homeScreen.roomName("Weekend Plans")]
        XCTAssertTrue(room.waitForExistence(timeout: 15))
        capture(app, name: "Build47-Chats")
        room.tap()
        let attachments = app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions]
        XCTAssertTrue(attachments.waitForExistence(timeout: 10))
        attachments.tap()
        let gifs = app.buttons[A11yIdentifiers.roomScreen.attachmentPickerGIF]
        XCTAssertTrue(gifs.waitForExistence(timeout: 5))
        capture(app, name: "Build47-GIF-Attachment")
        gifs.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 20))
        capture(app, name: "Build47-Giphy-Trending")
        search.tap()
        search.typeText("hello\n")
        let media = app.collectionViews.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "Media #")).firstMatch
        XCTAssertTrue(media.waitForExistence(timeout: 20))
        capture(app, name: "Build47-Giphy-Search")
        media.tap()
        capture(app, name: "Build47-Giphy-Selection")
        let select = app.buttons["Select GIF"]
        XCTAssertTrue(select.waitForExistence(timeout: 10))
        select.tap()
        XCTAssertTrue(app.buttons["Send"].firstMatch.waitForExistence(timeout: 30))
        capture(app, name: "Build47-GIF-Upload-Preview")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Giphy accessibility hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }
    
    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
