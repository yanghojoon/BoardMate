//
//  SessionStateTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

@testable import BoardMate
import Foundation
import Testing

@MainActor
struct SessionStateTests {
    private func select(_ tool: ToolSelection, in session: BoardMateSession) {
        session.navigation.select(tool, reduceMotion: true)
    }

    @Test func initialStateAndNewSessionAreIndependent() throws {
        let session = BoardMateSession()
        #expect(session.dice.count == 2)
        #expect(session.dice.result.isEmpty)
        #expect(session.dice.phase == .idle)
        #expect(session.hourglass.duration == 180)
        #expect(session.hourglass.remaining == 180)
        #expect(session.hourglass.phase == .idle)
        #expect(session.hourglass.deadline == nil)
        #expect(TokenDenomination.allCases.allSatisfy { session.tokens.quantities[$0] == 0 })
        #expect(session.navigation.selectedTool == nil)
        session.setActive(true)
        select(.dice, in: session)
        try session.setDiceCount("10")
        #expect(BoardMateSession().dice.count == 2)
    }

    @Test func navigationAndViewRecreationPreserveAllState() throws {
        let session = BoardMateSession(effects: SessionEffects(nextDie: { 4 }))
        session.setActive(true)
        select(.dice, in: session)
        try session.setDiceCount("3")
        let roll = try session.rollDice()
        session.completeDiceRoll(id: roll)
        select(.hourglass, in: session)
        try session.configureTimer(seconds: "90")
        try session.startTimer()
        select(.tokens, in: session)
        try session.addTokens([.five: 3, .fifty: 2])
        let dice = session.dice
        let timer = session.hourglass
        let tokens = session.tokens
        for tool in ToolSelection.allCases {
            select(tool, in: session)
            let panel = TabletopView(session: session)
            let root = ContentView(session: session)
            #expect(panel.session === session)
            #expect(root.session === session)
        }
        session.navigation.select(nil, reduceMotion: true)
        #expect(session.dice == dice)
        #expect(session.hourglass == timer)
        #expect(session.tokens == tokens)
    }

    @Test func rejectsActionsUntilLatestCameraRequestSettles() throws {
        let session = BoardMateSession()
        session.setActive(true)
        let old = session.navigation.select(.dice)
        let latest = session.navigation.select(.dice)
        session.navigation.complete(requestID: old)
        #expect(throws: InputValidation.Failure.unavailable) { try session.rollDice() }
        session.navigation.complete(requestID: latest)
        _ = try session.rollDice()
        #expect(session.dice.phase == .rolling)
    }

    @Test func diceRejectsDuplicateAndStaleCompletionAcrossSelection() throws {
        var draws = 0
        let session = BoardMateSession(effects: SessionEffects(nextDie: {
            draws += 1
            return 6
        }))
        session.setActive(true)
        select(.dice, in: session)
        let first = try session.rollDice()
        #expect(throws: InputValidation.Failure.unavailable) { try session.rollDice() }
        #expect(draws == 2)
        select(.tokens, in: session)
        session.completeDiceRoll(id: first)
        #expect(session.dice.phase == .idle)
        #expect(session.dice.result == [6, 6])
        select(.dice, in: session)
        let second = try session.rollDice()
        session.completeDiceRoll(id: first)
        #expect(session.dice.phase == .rolling)
        session.completeDiceRoll(id: second)
        #expect(session.dice.phase == .idle)
    }

    @Test func invalidInputsLeaveModelsUnchanged() throws {
        let session = BoardMateSession()
        session.setActive(true)
        select(.dice, in: session)
        for text in ["", "-1", "0", "1.5", "11"] {
            #expect(throws: (any Error).self) { try session.setDiceCount(text) }
        }
        #expect(session.dice.count == 2)
        select(.hourglass, in: session)
        for text in ["", "0", "-1", "1.5"] {
            #expect(throws: (any Error).self) { try session.configureTimer(seconds: text) }
        }
        #expect(session.hourglass.duration == 180)
        select(.tokens, in: session)
        try session.addTokens([.one: 2])
        let before = session.tokens
        #expect(throws: (any Error).self) { try session.addTokens([.five: 3, .one: -1]) }
        #expect(throws: (any Error).self) { try session.removeTokens("3", denomination: .one) }
        #expect(session.tokens == before)
        try session.removeTokens("2", denomination: .one)
        #expect(session.tokens.quantities[.one] == 0)
    }

    @Test func lifecyclePreservesDeadlineAndReflectsElapsedTime() throws {
        var now = Date(timeIntervalSince1970: 100)
        var feedback = 0
        let session = BoardMateSession(clock: SessionClock(now: { now }),
                                       effects: SessionEffects(timerFinished: { feedback += 1 }))
        session.setActive(true)
        select(.hourglass, in: session)
        try session.startTimer()
        let deadline = session.hourglass.deadline
        let run = session.hourglass.runID
        session.setActive(false)
        now = now.addingTimeInterval(60)
        session.setActive(true)
        #expect(session.hourglass.remaining == 120)
        #expect(session.hourglass.deadline == deadline)
        #expect(session.hourglass.runID == run)
        session.setActive(false)
        now = now.addingTimeInterval(180)
        session.setActive(true)
        session.refreshTime()
        #expect(session.hourglass.phase == .finished)
        #expect(session.hourglass.remaining == 0)
        #expect(feedback == 0)
    }

    @Test func activeExpiryDeliversOnceEvenOnAnotherToolAndResetInvalidatesRun() throws {
        var now = Date(timeIntervalSince1970: 100)
        var feedback = 0
        let session = BoardMateSession(clock: SessionClock(now: { now }),
                                       effects: SessionEffects(timerFinished: { feedback += 1 }))
        session.setActive(true)
        select(.hourglass, in: session)
        try session.configureTimer(seconds: "2")
        try session.startTimer()
        #expect(throws: (any Error).self) { try session.startTimer() }
        #expect(throws: (any Error).self) { try session.configureTimer(seconds: "4") }
        select(.dice, in: session)
        now = now.addingTimeInterval(2)
        session.refreshTime()
        session.refreshTime()
        #expect(feedback == 1)
        select(.hourglass, in: session)
        try session.resetTimer()
        #expect(session.hourglass.runID == nil)
        #expect(session.hourglass.deadline == nil)
        #expect(session.hourglass.remaining == 2)
        try session.startTimer()
        now = now.addingTimeInterval(2)
        session.refreshTime()
        #expect(feedback == 2)
    }

    @Test func inactiveAndWrongToolRejectInput() {
        let session = BoardMateSession()
        select(.dice, in: session)
        #expect(throws: InputValidation.Failure.unavailable) { try session.rollDice() }
        session.setActive(true)
        #expect(throws: InputValidation.Failure.unavailable) { try session.startTimer() }
        #expect(throws: InputValidation.Failure.unavailable) { try session.addTokens([.one: 1]) }
    }

    @Test func domainEnforcesBoundariesWithoutUI() throws {
        var dice = DiceState()
        #expect(throws: (any Error).self) { try dice.setCount(11) }
        #expect(throws: (any Error).self) { try dice.beginRoll(values: [0, 7], id: UUID()) }
        #expect(dice.result.isEmpty)
        var timer = HourglassState()
        for value in [0.0, -1, .infinity, .nan] {
            #expect(throws: (any Error).self) { try timer.configure(duration: value) }
        }
        var tokens = TokenState()
        try tokens.add([.one: Int.max])
        #expect(throws: (any Error).self) { try tokens.add([.one: 1, .five: 2]) }
        #expect(tokens.quantities[.one] == Int.max)
        #expect(tokens.quantities[.five] == 0)
        #expect(throws: (any Error).self) { try tokens.remove(0, denomination: .one) }
    }
}
