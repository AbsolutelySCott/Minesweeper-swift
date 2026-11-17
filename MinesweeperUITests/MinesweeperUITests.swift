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
    func testCreamGreenTheme() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        app.buttons["stats-button"].tap()
        XCTAssertTrue(app.staticTexts["战绩"].waitForExistence(timeout: 3))

        let creamTheme = app.descendants(matching: .any)["theme-creamGreen"]
        XCTAssertTrue(creamTheme.waitForExistence(timeout: 3))
        creamTheme.tap()
        attachScreenshot(app, name: "17-cream-green-stats")

        app.buttons["sheet-close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["sheet-close"].firstMatch.waitForNonExistence(timeout: 3))

        let center = tile(in: app, row: 4, column: 4)
        XCTAssertTrue(center.waitForExistence(timeout: 3))
        center.tap()
        let opened = NSPredicate(format: "value != '未翻开'")
        expectation(for: opened, evaluatedWith: center)
        waitForExpectations(timeout: 3)
        attachScreenshot(app, name: "18-cream-green-board")
    }

    @MainActor
    func testPhoneLandscapeLayout() throws {
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .phone, "Phone landscape layout is checked on iPhone.")
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        Thread.sleep(forTimeInterval: 2)

        XCTAssertTrue(app.buttons["fullscreen-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["fullscreen-button"].isHittable)
        XCTAssertTrue(app.buttons["stats-button"].isHittable)
        XCTAssertTrue(app.buttons["flag-mode-toggle"].isHittable)
        XCTAssertTrue(app.buttons["face-button"].isHittable)

        let board = app.scrollViews["board"]
        XCTAssertTrue(board.waitForExistence(timeout: 3))
        let center = tile(in: app, row: 4, column: 4)
        XCTAssertTrue(center.isHittable)
        center.tap()
        let opened = NSPredicate(format: "value != '未翻开'")
        expectation(for: opened, evaluatedWith: center)
        waitForExpectations(timeout: 3)

        attachScreenshot(app, name: "15-phone-landscape")

        app.buttons["fullscreen-button"].tap()
        XCTAssertTrue(app.buttons["fullscreen-exit"].waitForExistence(timeout: 3))
        attachScreenshot(app, name: "16-phone-landscape-fullscreen")
        app.buttons["fullscreen-exit"].tap()
    }

    @MainActor
    func testPinchZoomAndReset() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        let board = app.scrollViews["board"]
        XCTAssertTrue(board.waitForExistence(timeout: 3))
        board.pinch(withScale: 2.0, velocity: 1.0)

        let reset = app.descendants(matching: .any)["zoom-reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 3))
        attachScreenshot(app, name: "14-pinch-zoomed")

        let target = tile(in: app, row: 4, column: 4)
        XCTAssertTrue(target.waitForExistence(timeout: 2))
        XCTAssertTrue(target.isHittable)
        target.tap()

        let opened = NSPredicate(format: "value != '未翻开'")
        expectation(for: opened, evaluatedWith: target)
        waitForExpectations(timeout: 3)

        reset.tap()
        XCTAssertTrue(reset.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testFullScreenMode() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        let enterFullScreen = app.buttons["fullscreen-button"]
        XCTAssertTrue(enterFullScreen.waitForExistence(timeout: 3))
        enterFullScreen.tap()

        let exitFullScreen = app.buttons["fullscreen-exit"]
        XCTAssertTrue(exitFullScreen.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["fullscreen-flag-mode"].exists)
        XCTAssertFalse(app.buttons["stats-button"].exists)

        let centerTile = tile(in: app, row: 4, column: 4)
        XCTAssertTrue(centerTile.waitForExistence(timeout: 3))
        centerTile.tap()

        let opened = NSPredicate(format: "value != '未翻开'")
        expectation(for: opened, evaluatedWith: centerTile)
        waitForExpectations(timeout: 3)

        app.buttons["fullscreen-flag-mode"].tap()
        let hidden = firstHiddenTile(in: app)
        XCTAssertTrue(hidden.waitForExistence(timeout: 3))
        let hiddenIdentifier = hidden.identifier
        hidden.tap()

        let flaggedTile = app.descendants(matching: .any)[hiddenIdentifier]
        let isFlagged = NSPredicate(format: "value == '已插旗'")
        expectation(for: isFlagged, evaluatedWith: flaggedTile)
        waitForExpectations(timeout: 3)

        attachScreenshot(app, name: "13-fullscreen-mode")

        exitFullScreen.tap()
        XCTAssertTrue(app.buttons["stats-button"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["fullscreen-button"].exists)
        XCTAssertFalse(app.buttons["fullscreen-exit"].exists)
    }

    @MainActor
    func testFullScreenOrientationToggle() throws {
        try XCTSkipIf(
            UIDevice.current.userInterfaceIdiom == .pad,
            "The full-screen orientation switch is an iPhone affordance; iPad rotates natively."
        )
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["扫雷"].waitForExistence(timeout: 6))

        app.buttons["fullscreen-button"].tap()
        let orientationButton = app.buttons["fullscreen-orientation"]
        XCTAssertTrue(orientationButton.waitForExistence(timeout: 3))

        let window = app.windows.firstMatch
        let portrait = NSPredicate { _, _ in
            let frame = window.frame
            return frame.height > frame.width && frame.width > 0
        }
        expectation(for: portrait, evaluatedWith: window)
        waitForExpectations(timeout: 3)

        orientationButton.tap()
        let landscape = NSPredicate { _, _ in
            let frame = window.frame
            return frame.width > frame.height && frame.height > 0
        }
        expectation(for: landscape, evaluatedWith: window)
        waitForExpectations(timeout: 5)

        XCTAssertTrue(app.buttons["fullscreen-exit"].isHittable)
        XCTAssertTrue(app.buttons["fullscreen-flag-mode"].isHittable)
        attachScreenshot(app, name: "20-fullscreen-landscape-toggle")

        app.buttons["fullscreen-orientation"].tap()
        expectation(for: portrait, evaluatedWith: window)
        waitForExpectations(timeout: 5)

        app.buttons["fullscreen-exit"].tap()
        XCTAssertTrue(app.buttons["stats-button"].waitForExistence(timeout: 3))
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
