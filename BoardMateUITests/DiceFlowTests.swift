//
//  DiceFlowTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import XCTest

@MainActor
final class DiceFlowTests: XCTestCase {
    func testRollCountSelectionAndResultSurvivesNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--reduce-motion"]
        app.launch()
        app.buttons["select.dice"].tap()
        let roll = app.buttons["dice.roll"]
        XCTAssertTrue(roll.waitForExistence(timeout: 5))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        roll.tap()
        waitUntilEnabled(roll)
        let result = app.staticTexts["dice.result"]
        var original = result.value as? String
        XCTAssertEqual(original?.split(separator: ",").count, 2)
        app.buttons["select.tokens"].tap()
        app.buttons["select.dice"].tap()
        XCTAssertEqual(result.value as? String, original)

        for count in [1, 10] {
            app.buttons["dice.count"].tap()
            app.buttons["\(count)개"].tap()
            XCTAssertEqual(result.value as? String, original)
            let selected = XCTAttachment(screenshot: app.screenshot())
            selected.name = "Dice \(count) before roll"
            selected.lifetime = .keepAlways
            add(selected)
            roll.tap()
            waitUntilEnabled(roll)
            let values = (result.value as? String ?? "").split(separator: ",").compactMap { Int($0) }
            XCTAssertEqual(values.count, count)
            XCTAssertTrue(values.allSatisfy { (1...6).contains($0) })
            original = result.value as? String
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Dice \(count) results"
            attachment.lifetime = .keepAlways
            add(attachment)
            // The next count change must retain this result until another roll starts.
            if count == 1 { app.buttons["select.overview"].tap(); app.buttons["select.dice"].tap() }
        }
    }

    func testRollRecoversAfterSwitchAndBackground() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["select.dice"].tap()
        let roll = app.buttons["dice.roll"]
        waitUntilEnabled(roll)
        roll.tap()
        app.buttons["select.hourglass"].tap()
        app.buttons["select.dice"].tap()
        waitUntilEnabled(roll)
        XCTAssertEqual((app.staticTexts["dice.result"].value as? String)?.split(separator: ",").count, 2)
        roll.tap()
        let result = app.staticTexts["dice.result"].value as? String
        XCUIDevice.shared.press(.home)
        app.activate()
        waitUntilEnabled(roll)
        XCTAssertEqual(app.staticTexts["dice.result"].value as? String, result)
    }

    func testTenDiceMotionAndImmediateCountSelection() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["select.dice"].tap()
        let roll = app.buttons["dice.roll"]
        waitUntilEnabled(roll)
        app.buttons["dice.count"].tap()
        app.buttons["10개"].tap()
        for name in ["Ten dice selected before roll", "Ten dice in motion", "Ten dice landed"] {
            if name == "Ten dice in motion" { roll.tap() }
            if name == "Ten dice landed" { waitUntilEnabled(roll) }
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        XCTAssertEqual((app.staticTexts["dice.result"].value as? String)?.split(separator: ",").count, 10)
    }

    private func waitUntilEnabled(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    }
}
