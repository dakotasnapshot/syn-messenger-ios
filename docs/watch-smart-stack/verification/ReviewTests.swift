import XCTest

@MainActor final class ReviewTests: XCTestCase {
    func testCards() throws {
        continueAfterFailure = false
        for mode in ["missing", "corrupt", "empty", "unread", "long", "large"] {
            let app = XCUIApplication(); app.launchEnvironment["CARD_CASE"] = mode; app.launch()
            let card = app.descendants(matching: .any)["syn-card"].firstMatch
            XCTAssertTrue(card.waitForExistence(timeout: 10))
            XCTAssertTrue(card.label.contains("Syndicate"), card.label)
            let expected = try XCTUnwrap(["missing": "Open Syndicate to sync", "corrupt": "Open Syndicate to sync", "empty": "No unread messages", "unread": "3 unread", "long": "999+ unread", "large": "999+ unread"][mode])
            XCTAssertTrue(card.label.contains(expected), card.label)
            if mode == "unread" {
                XCTAssertTrue(card.label.contains("Team"), card.label)
            }
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); shot.name = mode; shot.lifetime = .keepAlways; add(shot); app.terminate()
        }
    }
}
