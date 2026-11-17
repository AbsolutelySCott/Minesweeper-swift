import XCTest

final class MinesweeperUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetGameState"]
        app.launch()
        return app
    }

    private func tile(in app: XCUIApplication, row: Int, column: Int) -> XCUIElement {
        app.descendants(matching: .any)["tile-\(row)-\(column)"]
    }

    private func firstHiddenTile(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'tile-' AND value == '未翻开'"))
            .firstMatch
    }

    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testGameplayFlagModeAndSheets() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))
        attachScreenshot(app, name: "01-launch")

        let centerTile = tile(in: app, row: 4, column: 4)
        XCTAssertTrue(centerTile.waitForExistence(timeout: 3))
        centerTile.tap()

        let opened = NSPredicate(format: "value != '未翻开'")
        expectation(for: opened, evaluatedWith: centerTile)
        waitForExpectations(timeout: 3)

        attachScreenshot(app, name: "02-board-in-play")

        let flagMode = app.buttons["flag-mode-toggle"]
        XCTAssertTrue(flagMode.waitForExistence(timeout: 2))
        flagMode.tap()

        let hidden = firstHiddenTile(in: app)
        XCTAssertTrue(hidden.waitForExistence(timeout: 2))
        let hiddenIdentifier = hidden.identifier
        hidden.tap()

        let flaggedTile = app.descendants(matching: .any)[hiddenIdentifier]
        let isFlagged = NSPredicate(format: "value == '已插旗'")
        expectation(for: isFlagged, evaluatedWith: flaggedTile)
        waitForExpectations(timeout: 3)

        attachScreenshot(app, name: "03-flagged-cell")

        let reset = app.buttons["face-button"]
        XCTAssertTrue(reset.exists)
        reset.tap()

        let isHiddenAgain = NSPredicate(format: "value == '未翻开'")
        expectation(for: isHiddenAgain, evaluatedWith: app.descendants(matching: .any)[hiddenIdentifier])
        waitForExpectations(timeout: 3)

        app.buttons["stats-button"].tap()
        XCTAssertTrue(app.staticTexts["战绩"].waitForExistence(timeout: 3))
        attachScreenshot(app, name: "04-stats")
        app.buttons["sheet-close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["sheet-close"].firstMatch.waitForNonExistence(timeout: 3))

        app.buttons["help-button"].tap()
        XCTAssertTrue(app.staticTexts["玩法"].waitForExistence(timeout: 3))
        attachScreenshot(app, name: "05-help")
        app.buttons["sheet-close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["sheet-close"].firstMatch.waitForNonExistence(timeout: 3))

        let expert = app.buttons["difficulty-expert"]
        XCTAssertTrue(expert.waitForExistence(timeout: 2))
        expert.tap()
        XCTAssertTrue(app.staticTexts["高级 · 30 × 16 · 99 雷"].waitForExistence(timeout: 3))
        attachScreenshot(app, name: "06-expert-board")
    }

    @MainActor
    func testExpertBoardScrollsHorizontally() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        app.buttons["difficulty-expert"].tap()
        XCTAssertTrue(app.staticTexts["高级 · 30 × 16 · 99 雷"].waitForExistence(timeout: 3))

        let board = app.scrollViews["board"]
        XCTAssertTrue(board.waitForExistence(timeout: 3))

        let farEdgeTile = tile(in: app, row: 7, column: 29)
        XCTAssertTrue(farEdgeTile.exists)
        XCTAssertFalse(farEdgeTile.isHittable, "The far edge of the expert board starts outside the viewport.")

        for _ in 0..<4 where !farEdgeTile.isHittable {
            board.swipeLeft()
        }

        XCTAssertTrue(farEdgeTile.isHittable, "The board should scroll to reveal the far edge.")
        attachScreenshot(app, name: "08-expert-scrolled")
    }

    @MainActor
    func testLossShowsResultAndRecordsStats() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        app.buttons["difficulty-expert"].tap()
        XCTAssertTrue(app.staticTexts["高级 · 30 × 16 · 99 雷"].waitForExistence(timeout: 3))

        var attempts = 0
        while !app.staticTexts["踩到地雷了"].exists && attempts < 30 {
            let hidden = firstHiddenTile(in: app)
            guard hidden.waitForExistence(timeout: 1) else { break }
            hidden.tap()
            attempts += 1
            Thread.sleep(forTimeInterval: 0.45)
        }

        XCTAssertTrue(app.staticTexts["踩到地雷了"].waitForExistence(timeout: 4))
        attachScreenshot(app, name: "10-loss-result")

        XCTAssertTrue(app.buttons["result-replay"].exists)
        app.buttons["result-inspect"].tap()
        XCTAssertTrue(app.buttons["result-inspect"].waitForNonExistence(timeout: 3))
        attachScreenshot(app, name: "11-board-after-loss")

        app.buttons["stats-button"].tap()
        XCTAssertTrue(app.staticTexts["战绩"].waitForExistence(timeout: 3))

        let summary = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS '总战绩'"))
            .firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(summary.label.contains("1 局"), "A loss should count toward games played.")
        attachScreenshot(app, name: "12-stats-after-loss")
    }

    @MainActor
    func testTabletLandscapeLayout() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "Tablet layout is only checked on iPad.")
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        XCTAssertTrue(app.buttons["difficulty-expert"].waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(app.buttons["difficulty-expert"].isHittable)

        let windowFrame = app.windows.firstMatch.frame
        XCTAssertGreaterThan(windowFrame.width, windowFrame.height, "The app window should rotate to landscape.")
        XCTAssertLessThanOrEqual(app.buttons["help-button"].frame.maxX, windowFrame.maxX)
        attachScreenshot(app, name: "09-ipad-landscape")
    }

    @MainActor
    func testLongPressPlacesAFlag() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        tile(in: app, row: 4, column: 4).tap()

        let hidden = firstHiddenTile(in: app)
        XCTAssertTrue(hidden.waitForExistence(timeout: 3))
        let identifier = hidden.identifier
        hidden.press(forDuration: 0.65)

        let flaggedTile = app.descendants(matching: .any)[identifier]
        let isFlagged = NSPredicate(format: "value == '已插旗'")
        expectation(for: isFlagged, evaluatedWith: flaggedTile)
        waitForExpectations(timeout: 3)
        Thread.sleep(forTimeInterval: 0.6)
        XCTAssertEqual(flaggedTile.value as? String, "已插旗", "The flag should remain after the long press ends.")

        XCTAssertTrue(app.staticTexts["剩余地雷"].exists)
        attachScreenshot(app, name: "07-long-press-flag")
    }
}
