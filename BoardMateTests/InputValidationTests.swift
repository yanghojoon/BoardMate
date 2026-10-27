//
//  InputValidationTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

@testable import BoardMate
import Testing

struct InputValidationTests {
    @Test(arguments: ["", "-1", "+1", "1.5", " 2", "2 ", "１２", "abc", String(repeating: "9", count: 50)])
    func rejectsMalformedInteger(_ text: String) {
        #expect(throws: InputValidation.Failure.invalidInteger) {
            try InputValidation.integer(text, in: 1...10)
        }
    }

    @Test(arguments: ["0", "11"])
    func rejectsOutsideRange(_ text: String) {
        #expect(throws: InputValidation.Failure.outOfRange) {
            try InputValidation.integer(text, in: 1...10)
        }
    }

    @Test func acceptsRangeBoundariesAndExplicitZero() throws {
        #expect(try InputValidation.integer("1", in: 1...10) == 1)
        #expect(try InputValidation.integer("10", in: 1...10) == 10)
        #expect(try InputValidation.integer("0", in: 0...10) == 0)
    }
}
