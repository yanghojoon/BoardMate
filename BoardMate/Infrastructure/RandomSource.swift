//
//  RandomSource.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

enum RandomSource {
    static func nextDie() -> Int { Int.random(in: 1...6) }
}
