//
//  HourglassControllerTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

@testable import BoardMate
import Foundation
import RealityKit
import Testing

@MainActor
struct HourglassControllerTests {
    private func prepare(_ session: BoardMateSession) -> HourglassController {
        session.setActive(true)
        session.navigation.select(.hourglass, reduceMotion: true)
        return HourglassController(session: session)
    }

    @Test func validatesMinuteSecondBoundariesAtomically() {
        let session = BoardMateSession()
        let controller = prepare(session)
        for pair in [("", "1"), ("0", "0"), ("-1", "0"), ("60", "0"), ("0", "60"), ("1", "1.5")] {
            controller.configure(minutes: pair.0, seconds: pair.1)
            #expect(controller.inputError != nil)
            #expect(session.hourglass.duration == 180)
        }
        controller.configure(minutes: "59", seconds: "59")
        #expect(session.hourglass.duration == 3599)
        #expect(controller.inputError == nil)
        controller.configure(minutes: "0", seconds: "1")
        #expect(session.hourglass.duration == 1)
    }

    @Test func clockAndToolChangesPreserveRunAndResetRestoresConfiguredTime() {
        var now = Date(timeIntervalSince1970: 100)
        let session = BoardMateSession(clock: SessionClock(now: { now }))
        let controller = prepare(session)
        controller.configure(minutes: "1", seconds: "0")
        now += 20
        session.refreshTime()
        #expect(session.hourglass.remaining == 60)
        controller.start()
        let run = session.hourglass.runID
        controller.start()
        #expect(session.hourglass.runID == run)
        controller.configure(minutes: "0", seconds: "1")
        #expect(session.hourglass.duration == 60)
        session.navigation.select(.dice, reduceMotion: true)
        now += 20
        session.refreshTime()
        #expect(session.hourglass.remaining == 40)
        #expect(abs(session.hourglass.progress - 1 / 3.0) < 0.0001)
        session.navigation.select(.hourglass, reduceMotion: true)
        controller.reset()
        #expect(session.hourglass.phase == .idle)
        #expect(session.hourglass.remaining == 60)
        #expect(session.hourglass.progress == 0)
        #expect(session.hourglass.runID == nil)
    }

    @Test func expiryFeedbackIsConsumedPerRunAcrossLifecycleAndReset() {
        var now = Date(timeIntervalSince1970: 100)
        var feedback = 0
        let session = BoardMateSession(clock: SessionClock(now: { now }),
                                       effects: SessionEffects(timerFinished: { feedback += 1 }))
        let controller = prepare(session)
        controller.configure(minutes: "0", seconds: "2")
        controller.start()
        let oldRun = session.hourglass.runID
        controller.reset()
        controller.start()
        #expect(session.hourglass.runID != oldRun)
        // No callback carries a cached deadline: all ticks read the current run.
        now += 1
        session.refreshTime()
        #expect(session.hourglass.remaining == 1)
        #expect(feedback == 0)
        session.navigation.select(.tokens, reduceMotion: true)
        now += 1
        session.refreshTime()
        session.refreshTime()
        #expect(feedback == 1)
        #expect(session.hourglass.consumedCompletionID == session.hourglass.runID)
        session.setActive(false)
        session.setActive(true)
        #expect(feedback == 1)
        session.navigation.select(.hourglass, reduceMotion: true)
        controller.reset()
        controller.start()
        now += 2
        session.refreshTime()
        #expect(feedback == 2)
    }

    @Test func inactiveExpiryAndDeactivationBoundaryNeverDeliverLateFeedback() {
        var now = Date(timeIntervalSince1970: 100)
        var feedback = 0
        let session = BoardMateSession(clock: SessionClock(now: { now }),
                                       effects: SessionEffects(timerFinished: { feedback += 1 }))
        let controller = prepare(session)
        controller.configure(minutes: "1", seconds: "0")
        controller.start()
        session.setActive(false)
        now += 20
        session.setActive(true)
        #expect(session.hourglass.remaining == 40)
        now += 40
        session.setActive(false)
        session.setActive(true)
        session.refreshTime()
        #expect(session.hourglass.remaining == 0)
        #expect(session.hourglass.phase == .finished)
        #expect(feedback == 0)
        controller.reset()
        controller.start()
        session.setActive(false)
        now += 80
        session.setActive(true)
        #expect(session.hourglass.remaining == 0)
        #expect(feedback == 0)
    }

    @Test func inputGatesAndClockRollbackAreSafe() throws {
        let session = BoardMateSession()
        let controller = HourglassController(session: session)
        #expect(!controller.canStart)
        controller.start()
        #expect(session.hourglass.phase == .idle)
        _ = prepare(session)
        let request = session.navigation.select(.hourglass)
        #expect(!controller.canStart)
        session.navigation.complete(requestID: request)
        #expect(controller.canStart)
        for text in ["0", "3600", "-1", ""] {
            #expect(throws: (any Error).self) { try session.configureTimer(seconds: text) }
        }
        var state = HourglassState()
        let now = Date(timeIntervalSince1970: 100)
        try state.start(at: now, id: UUID())
        state.refresh(at: now - 20)
        #expect(state.remaining == state.duration)
        #expect(state.progress == 0)
    }

    @Test func sandTracksStateAndStopsStreamWhenNotRunning() throws {
        let root = HourglassEntityFactory.make()
        let stream = try #require(root.findEntity(named: "sand-stream"))
        let upper = try #require(root.findEntity(named: "sand-upper"))
        let lower = try #require(root.findEntity(named: "sand-lower"))
        var state = HourglassState()
        let now = Date(timeIntervalSince1970: 100)
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: false)
        #expect(!stream.isEnabled)
        try state.start(at: now, id: UUID())
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: false)
        #expect(stream.isEnabled)
        state.refresh(at: now + 90)
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: false)
        #expect(abs(pow(upper.scale.x, 3) - 0.5) < 0.0001)
        #expect(abs(pow(lower.scale.x, 3) - 0.5) < 0.0001)
        HourglassEntityFactory.update(state, on: root, isActive: false, reduceMotion: false)
        #expect(!stream.isEnabled)
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: true)
        #expect(!stream.isEnabled)
        state.refresh(at: now + 200)
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: false)
        #expect(!upper.isEnabled && lower.isEnabled && !stream.isEnabled)
        state.reset()
        HourglassEntityFactory.update(state, on: root, isActive: true, reduceMotion: false)
        #expect(upper.isEnabled && !lower.isEnabled && !stream.isEnabled)
    }
}
