//
//  HourglassFlowTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import XCTest

@MainActor
final class HourglassFlowTests: XCTestCase {
    func testConfigurationValidationAndReset() {
        let app = launchHourglass()
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "180")
        configure(minutes: "0", seconds: "0", in: app)
        XCTAssertTrue(app.staticTexts["hourglass.hint"].label.contains("1초~59분 59초"))
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "180")
        configure(minutes: "0", seconds: "30", in: app)
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "30")
        attach("Hourglass idle", in: app)
        app.buttons["hourglass.start"].tap()
        XCTAssertFalse(app.buttons["hourglass.start"].isEnabled)
        XCTAssertFalse(app.buttons["hourglass.apply"].isEnabled)
        app.buttons["hourglass.reset"].tap()
        assertPhase("idle", in: app)
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "30")
        XCTAssertTrue(app.buttons["hourglass.start"].isEnabled)
    }

    func testRunningTimerSurvivesToolRoundTripAndBackground() {
        let app = launchHourglass()
        configure(minutes: "0", seconds: "30", in: app)
        app.buttons["hourglass.start"].tap()
        app.buttons["select.dice"].tap()
        app.buttons["select.hourglass"].tap()
        assertPhase("running", in: app)
        let before = Int(app.staticTexts["hourglass.remaining"].value as? String ?? "") ?? 0
        XCUIDevice.shared.press(.home)
        app.activate()
        assertPhase("running", in: app)
        let after = Int(app.staticTexts["hourglass.remaining"].value as? String ?? "") ?? 0
        XCTAssertGreaterThan(after, 0)
        XCTAssertLessThan(after, before)
        attach("Hourglass resumed", in: app)
        app.buttons["hourglass.reset"].tap()
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "30")
    }

    func testExpiryOnOtherToolAndRestartAfterReset() {
        let app = launchHourglass()
        configure(minutes: "0", seconds: "2", in: app)
        app.buttons["hourglass.start"].tap()
        app.buttons["select.tokens"].tap()
        app.buttons["select.hourglass"].tap()
        assertPhase("finished", in: app)
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "0")
        XCTAssertFalse(app.buttons["hourglass.start"].isEnabled)
        attach("Hourglass finished", in: app)
        app.buttons["hourglass.reset"].tap()
        assertPhase("idle", in: app)
        XCTAssertEqual(app.staticTexts["hourglass.remaining"].value as? String, "2")
        app.buttons["hourglass.start"].tap()
        assertPhase("finished", in: app)
    }

    private func launchHourglass() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reduce-motion"]
        app.launch()
        app.buttons["select.hourglass"].tap()
        XCTAssertTrue(app.buttons["hourglass.start"].waitForExistence(timeout: 5))
        return app
    }

    private func configure(minutes: String, seconds: String, in app: XCUIApplication) {
        for (identifier, value) in [("hourglass.minutes", minutes), ("hourglass.seconds", seconds)] {
            let field = app.textFields[identifier]
            // Tap after the centered digits so deletion starts at the end of the value.
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            let current = field.value as? String ?? ""
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + value)
            XCTAssertEqual(field.value as? String, value)
        }
        app.buttons["완료"].tap()
        app.buttons["hourglass.apply"].tap()
    }

    private func assertPhase(_ phase: String, in app: XCUIApplication) {
        let element = app.staticTexts["hourglass.phase"]
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", phase), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed)
    }

    private func attach(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
