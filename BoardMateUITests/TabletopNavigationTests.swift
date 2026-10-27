//
//  TabletopNavigationTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import XCTest

@MainActor
final class TabletopNavigationTests: XCTestCase {
    func testDirectToolNavigationAndReturnToOverview() {
        let app = XCUIApplication()
        app.launch()

        assertSelection("overview", in: app)
        attachScreenshot("Tabletop overview", in: app)
        for tool in ["dice", "hourglass", "tokens"] {
            app.buttons["select.\(tool)"].tap()
            assertSelection(tool, in: app)
            assertTransitionSettled(in: app)
            attachScreenshot("Tabletop \(tool)", in: app)
        }

        app.buttons["select.overview"].tap()
        assertSelection("overview", in: app)
        assertTransitionSettled(in: app)
    }

    private func attachScreenshot(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testRapidSelectionSettlesOnLastTool() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["select.dice"].tap()
        app.buttons["select.hourglass"].tap()
        app.buttons["select.tokens"].tap()

        assertSelection("tokens", in: app)
        assertTransitionSettled(in: app)
        assertSelection("tokens", in: app)
    }

    func testReduceMotionNavigationSettlesAndReturnsToOverview() {
        let app = XCUIApplication()
        app.launchArguments = ["--reduce-motion"]
        app.launch()

        app.buttons["select.hourglass"].tap()
        assertSelection("hourglass", in: app)
        assertTransitionSettled(in: app)

        app.buttons["select.tokens"].tap()
        assertSelection("tokens", in: app)
        assertTransitionSettled(in: app)

        app.buttons["select.overview"].tap()
        assertSelection("overview", in: app)
        assertTransitionSettled(in: app)
    }

    func testSceneToolsCanBeSelectedByTappingTheirGeometry() {
        let app = XCUIApplication()
        app.launchArguments = ["--reduce-motion"]
        app.launch()
        assertSelection("overview", in: app)

        // Fixed portrait overview framing on the iPhone 17 Pro verification device.
        let targets: [(String, CGVector)] = [
            ("dice", CGVector(dx: 0.20, dy: 0.49)),
            ("hourglass", CGVector(dx: 0.50, dy: 0.40)),
            ("tokens", CGVector(dx: 0.80, dy: 0.50))
        ]
        for (tool, position) in targets {
            app.coordinate(withNormalizedOffset: position).tap()
            assertSelection(tool, in: app)
            assertTransitionSettled(in: app)
            app.buttons["select.overview"].tap()
            assertSelection("overview", in: app)
            assertTransitionSettled(in: app)
        }
    }

    func testHourglassProgressVisualSamples() {
        for progress in ["0", "0.5", "1"] {
            let app = XCUIApplication()
            app.launchArguments = ["--reduce-motion", "--hourglass-progress", progress]
            app.launch()

            app.buttons["select.hourglass"].tap()
            assertSelection("hourglass", in: app)
            assertTransitionSettled(in: app)
            attachScreenshot("Hourglass progress \(progress)", in: app)
            app.terminate()
        }
    }

    private func assertSelection(
        _ value: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let selection = app.descendants(matching: .any)["tabletop.selection"]
        XCTAssertTrue(selection.waitForExistence(timeout: 5), file: file, line: line)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", value),
            object: selection
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, file: file, line: line)
    }

    private func assertTransitionSettled(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let transition = app.descendants(matching: .any)["tabletop.transition"]
        XCTAssertTrue(transition.waitForExistence(timeout: 5), file: file, line: line)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == 'idle'"),
            object: transition
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, file: file, line: line)
    }
}
