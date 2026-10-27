//
//  HourglassState.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation

struct HourglassState: Equatable {
    enum Phase { case idle, running, finished }

    private(set) var duration: TimeInterval = 180
    private(set) var remaining: TimeInterval = 180
    private(set) var phase = Phase.idle
    private(set) var deadline: Date?
    private(set) var runID: UUID?

    mutating func configure(duration: TimeInterval) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard duration.isFinite, duration > 0, duration <= Double(Int.max) else {
            throw InputValidation.Failure.outOfRange
        }
        self.duration = duration
        remaining = duration
    }

    mutating func start(at now: Date, id: UUID) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        deadline = now.addingTimeInterval(duration)
        runID = id
        phase = .running
    }

    mutating func refresh(at now: Date) {
        guard phase == .running, let deadline else { return }
        remaining = max(0, deadline.timeIntervalSince(now))
        if remaining == 0 { phase = .finished }
    }

    mutating func reset() {
        remaining = duration
        deadline = nil
        runID = nil
        phase = .idle
    }
}
