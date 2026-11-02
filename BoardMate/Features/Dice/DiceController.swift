//
//  DiceController.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import Observation

@MainActor @Observable
final class DiceController {
    let session: BoardMateSession
    private(set) var inputError: String?

    init(session: BoardMateSession) { self.session = session }

    var canRoll: Bool {
        session.isActive && session.navigation.canExecute
            && session.navigation.selectedTool == .dice && session.dice.phase == .idle
    }

    func roll() {
        guard canRoll else { return }
        do {
            try session.rollDice()
            inputError = nil
        } catch {
            inputError = "주사위를 굴릴 수 없습니다. 다시 시도해 주세요."
        }
    }

    func setCount(_ text: String) {
        do {
            try session.setDiceCount(text)
            inputError = nil
        } catch {
            inputError = "주사위 개수는 1~10 사이의 정수로 선택해 주세요."
        }
    }
}
