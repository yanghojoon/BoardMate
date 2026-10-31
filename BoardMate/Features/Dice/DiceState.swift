//
//  DiceState.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation

struct DiceState: Equatable {
    static let rollDuration: TimeInterval = 1.2
    enum Phase { case idle, rolling }

    private(set) var count = 2
    private(set) var result: [Int] = []
    private(set) var phase = Phase.idle
    private(set) var rollID: UUID?
    private(set) var deadline: Date?

    /// Selection updates the table immediately; previous numeric results stay intact.
    var displayedValues: [Int] {
        Array(result.prefix(count)) + Array(repeating: 1, count: max(0, count - result.count))
    }

    mutating func setCount(_ count: Int) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard (1...10).contains(count) else { throw InputValidation.Failure.outOfRange }
        self.count = count
    }

    mutating func beginRoll(values: [Int], id: UUID, at now: Date = Date()) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard values.count == count, values.allSatisfy({ (1...6).contains($0) }) else {
            throw InputValidation.Failure.outOfRange
        }
        result = values
        rollID = id
        phase = .rolling
        deadline = now.addingTimeInterval(Self.rollDuration)
    }

    mutating func completeRoll(id: UUID) {
        guard phase == .rolling, rollID == id else { return }
        phase = .idle
        deadline = nil
    }

    mutating func refresh(at now: Date) {
        guard let deadline, now >= deadline, let rollID else { return }
        completeRoll(id: rollID)
    }
}
