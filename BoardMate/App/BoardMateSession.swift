//
//  BoardMateSession.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation
import Observation

@MainActor @Observable
final class BoardMateSession {
    let navigation = CameraCoordinator()
    private(set) var dice = DiceState()
    private(set) var hourglass = HourglassState()
    private(set) var tokens = TokenState()
    private(set) var isActive = false
    private var deliveredTimerID: UUID?
    private let clock: SessionClock
    private let effects: SessionEffects

    init(clock: SessionClock = SessionClock(), effects: SessionEffects = SessionEffects()) {
        self.clock = clock
        self.effects = effects
    }

    func setActive(_ active: Bool) {
        // Refresh before activating: expiry during inactivity is reflected without late feedback.
        refreshTime()
        isActive = active
        if !active, let id = dice.rollID { dice.completeRoll(id: id) }
    }

    func setDiceCount(_ text: String) throws {
        try requireTool(.dice)
        try dice.setCount(InputValidation.integer(text, in: 1...10))
    }

    @discardableResult
    func rollDice() throws -> UUID {
        try requireTool(.dice)
        guard dice.phase == .idle else { throw InputValidation.Failure.unavailable }
        let values = (0..<dice.count).map { _ in effects.nextDie() }
        let id = UUID()
        try dice.beginRoll(values: values, id: id, at: clock.now())
        return id
    }

    func completeDiceRoll(id: UUID) {
        dice.completeRoll(id: id)
    }

    func configureTimer(seconds text: String) throws {
        try requireTool(.hourglass)
        try hourglass.configure(duration: TimeInterval(InputValidation.integer(text, in: 1...Int.max)))
    }

    func startTimer() throws {
        try requireTool(.hourglass)
        try hourglass.start(at: clock.now(), id: UUID())
    }

    func resetTimer() throws {
        try requireTool(.hourglass)
        hourglass.reset()
        deliveredTimerID = nil
    }

    func refreshTime() {
        // Avoid publishing an unchanged DiceState on every timer tick.
        if let deadline = dice.deadline, clock.now() >= deadline {
            dice.refresh(at: clock.now())
        }
        let wasRunning = hourglass.phase == .running
        hourglass.refresh(at: clock.now())
        guard wasRunning, hourglass.phase == .finished,
              let id = hourglass.runID, deliveredTimerID != id else { return }
        deliveredTimerID = id
        if isActive { effects.timerFinished() }
    }

    func addTokens(_ additions: [TokenDenomination: Int]) throws {
        try requireTool(.tokens)
        try tokens.add(additions)
    }

    func removeTokens(_ text: String, denomination: TokenDenomination) throws {
        try requireTool(.tokens)
        try tokens.remove(InputValidation.integer(text, in: 1...Int.max), denomination: denomination)
    }

    private func requireTool(_ tool: ToolSelection) throws {
        guard isActive, navigation.canExecute, navigation.selectedTool == tool else {
            throw InputValidation.Failure.unavailable
        }
    }
}
