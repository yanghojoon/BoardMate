//
//  SessionClock.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation

@MainActor
struct SessionClock {
    var now: () -> Date = { Date() }
}

@MainActor
struct SessionEffects {
    var nextDie: () -> Int = { RandomSource.nextDie() }
    // Step 05 supplies the device feedback implementation.
    var timerFinished: () -> Void = {}
}
