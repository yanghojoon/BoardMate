//
//  InputValidation.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

enum InputValidation {
    enum Failure: Error, Equatable {
        case invalidInteger
        case outOfRange
        case unavailable
    }

    static func integer(_ text: String, in range: ClosedRange<Int>) throws -> Int {
        guard !text.isEmpty, text.utf8.allSatisfy({ (48...57).contains($0) }),
              let value = Int(text) else {
            throw Failure.invalidInteger
        }
        guard range.contains(value) else { throw Failure.outOfRange }
        return value
    }
}
