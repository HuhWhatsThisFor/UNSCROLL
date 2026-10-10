import XCTest

final class PreviewFlowTests: XCTestCase {
    @MainActor func testOnboardingSelectionFocusAndEarlyStop() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["UNSCROLL_TEST_NAMESPACE"] = UUID().uuidString
        app.launchEnvironment["UNSCROLL_TEST_APPEARANCE"] = "dark"
        app.launch()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 15))
        app.buttons["Continue"].tap()
        app.buttons["Continue"].tap()
        let permission = app.buttons["Simulate permission"]
        XCTAssertTrue(permission.waitForExistence(timeout: 5)); permission.tap()
        app.buttons["Continue"].tap()
        app.buttons["Choose demo apps"].tap()
        XCTAssertTrue(app.buttons["Social feed"].waitForExistence(timeout: 5))
        app.buttons["Social feed"].tap(); app.buttons["Save"].tap()
        app.buttons["Find your focus"].tap()
        let start = app.buttons["Start demo focus"]
        XCTAssertTrue(start.waitForExistence(timeout: 5)); XCTAssertTrue(start.isEnabled)
        attach(app, name: "Home — preview")
        start.tap()
        let stop = app.buttons["End session early"]
        if !stop.isHittable { app.swipeUp() }
        XCTAssertTrue(stop.waitForExistence(timeout: 5))
        attach(app, name: "Focus — simulated restrictions")
        stop.tap()
        app.buttons["End session"].tap()
        XCTAssertTrue(app.staticTexts["Your time is yours."].waitForExistence(timeout: 5))
        app.buttons["Back to your day"].tap()
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Ended early"].waitForExistence(timeout: 5))
        attach(app, name: "History — honest early-ended record")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        if !app.buttons["Privacy"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Privacy"].waitForExistence(timeout: 5))
        app.buttons["Privacy"].tap()
        XCTAssertTrue(app.staticTexts["Your focus belongs to you."].waitForExistence(timeout: 5))
    }
    @MainActor private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
