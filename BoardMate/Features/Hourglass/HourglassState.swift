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
    private(set) var consumedCompletionID: UUID?

    var progress: Double { min(max(1 - remaining / duration, 0), 1) }

    mutating func configure(duration: TimeInterval) throws {
        guard phase == .idle else { throw InputValidation.Failure.unavailable }
        guard duration.isFinite, duration >= 1, duration <= 3599 else {
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
        remaining = min(duration, max(0, deadline.timeIntervalSince(now)))
        if remaining == 0 { phase = .finished }
    }

    mutating func consumeCompletion() -> Bool {
        guard phase == .finished, let runID, consumedCompletionID != runID else { return false }
        consumedCompletionID = runID
        return true
    }

    mutating func reset() {
        remaining = duration
        deadline = nil
        runID = nil
        consumedCompletionID = nil
        phase = .idle
    }
}
