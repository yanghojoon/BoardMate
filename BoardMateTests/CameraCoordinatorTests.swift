//
//  CameraCoordinatorTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

@testable import BoardMate
import XCTest

@MainActor
final class CameraCoordinatorTests: XCTestCase {
    func testInjectedActionIsBlockedUntilLatestTransitionCompletes() {
        let coordinator = CameraCoordinator()
        var executedTools: [ToolSelection] = []
        XCTAssertFalse(coordinator.performToolAction { executedTools.append($0) })
        let request = coordinator.select(.dice)
        XCTAssertFalse(coordinator.performToolAction { executedTools.append($0) })
        XCTAssertTrue(executedTools.isEmpty)
        coordinator.complete(requestID: request)
        XCTAssertTrue(coordinator.performToolAction { executedTools.append($0) })
        XCTAssertEqual(executedTools, [.dice])
    }

    func testOverviewDoesNotAcceptToolExecution() {
        let coordinator = CameraCoordinator()

        XCTAssertNil(coordinator.selectedTool)
        XCTAssertFalse(coordinator.canExecute)
        XCTAssertFalse(coordinator.isTransitioning)
    }

    func testLatestRequestWinsWhenEarlierCompletionArrivesLate() {
        let coordinator = CameraCoordinator()
        let diceRequest = coordinator.select(.dice)
        let hourglassRequest = coordinator.select(.hourglass)
        let tokenRequest = coordinator.select(.tokens)

        coordinator.complete(requestID: diceRequest)
        coordinator.complete(requestID: hourglassRequest)

        XCTAssertEqual(coordinator.selectedTool, .tokens)
        XCTAssertEqual(coordinator.requestID, tokenRequest)
        XCTAssertTrue(coordinator.isTransitioning)
        XCTAssertFalse(coordinator.canExecute)

        coordinator.complete(requestID: tokenRequest)

        XCTAssertEqual(coordinator.selectedTool, .tokens)
        XCTAssertFalse(coordinator.isTransitioning)
        XCTAssertTrue(coordinator.canExecute)
    }

    func testReturnToOverviewInvalidatesPendingToolCompletion() {
        let coordinator = CameraCoordinator()
        let toolRequest = coordinator.select(.dice)
        let overviewRequest = coordinator.select(nil)

        coordinator.complete(requestID: toolRequest)

        XCTAssertNil(coordinator.selectedTool)
        XCTAssertTrue(coordinator.isTransitioning)
        XCTAssertFalse(coordinator.canExecute)

        coordinator.complete(requestID: overviewRequest)

        XCTAssertNil(coordinator.selectedTool)
        XCTAssertFalse(coordinator.isTransitioning)
        XCTAssertFalse(coordinator.canExecute)
    }

    func testReduceMotionSettlesImmediatelyAndIgnoresOldCompletion() {
        let coordinator = CameraCoordinator()
        let previousRequest = coordinator.select(.dice)
        let currentRequest = coordinator.select(.hourglass, reduceMotion: true)

        coordinator.complete(requestID: previousRequest)

        XCTAssertEqual(coordinator.requestID, currentRequest)
        XCTAssertEqual(coordinator.selectedTool, .hourglass)
        XCTAssertFalse(coordinator.isTransitioning)
        XCTAssertTrue(coordinator.canExecute)

        coordinator.select(nil, reduceMotion: true)

        XCTAssertNil(coordinator.selectedTool)
        XCTAssertFalse(coordinator.isTransitioning)
        XCTAssertFalse(coordinator.canExecute)
    }
}
