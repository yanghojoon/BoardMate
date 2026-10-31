//
//  HourglassController.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import Observation

@MainActor @Observable
final class HourglassController {
    let session: BoardMateSession
    private(set) var inputError: String?

    init(session: BoardMateSession) { self.session = session }

    private var canExecute: Bool {
        session.isActive && session.navigation.canExecute && session.navigation.selectedTool == .hourglass
    }

    var canConfigure: Bool { canExecute && session.hourglass.phase == .idle }
    var canStart: Bool { canConfigure }
    var canReset: Bool { canExecute }

    func configure(minutes: String, seconds: String) {
        do {
            let minutes = try InputValidation.integer(minutes, in: 0...59)
            let seconds = try InputValidation.integer(seconds, in: 0...59)
            try session.configureTimer(seconds: String(minutes * 60 + seconds))
            inputError = nil
        } catch {
            inputError = "시간은 1초~59분 59초로 입력해 주세요. 실행 후에는 먼저 리셋하세요."
        }
    }

    func start() {
        guard canStart else { return }
        do {
            try session.startTimer()
            inputError = nil
        } catch {
            inputError = "모래시계를 시작할 수 없습니다. 다시 시도해 주세요."
        }
    }

    func reset() {
        guard canReset else { return }
        do {
            try session.resetTimer()
            inputError = nil
        } catch {
            inputError = "모래시계를 리셋할 수 없습니다. 다시 시도해 주세요."
        }
    }
}
