//
//  DiceState.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation

struct DiceState: Equatable {
    enum Phase { case idle, rolling }

    private(set) var count = 2
    private(set) var result: [Int] = []
    private(set) var phase = Phase.idle
    private(set) var rollID: UUID?

    mutating func setCount(_ count: Int) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard (1...10).contains(count) else { throw InputValidation.Failure.outOfRange }
        self.count = count
    }

    mutating func beginRoll(values: [Int], id: UUID) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard values.count == count, values.allSatisfy({ (1...6).contains($0) }) else {
            throw InputValidation.Failure.outOfRange
        }
        result = values
        rollID = id
        phase = .rolling
    }

    mutating func completeRoll(id: UUID) {
        guard phase == .rolling, rollID == id else { return }
        phase = .idle
    }
}
