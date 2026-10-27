//
//  TokenState.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

enum TokenDenomination: Int, CaseIterable {
    case one = 1, five = 5, ten = 10, twenty = 20, fifty = 50
}

struct TokenState: Equatable {
    private(set) var quantities = Dictionary(uniqueKeysWithValues: TokenDenomination.allCases.map { ($0, 0) })

    mutating func add(_ additions: [TokenDenomination: Int]) throws {
        var updated = quantities
        for (denomination, count) in additions {
            let (sum, overflow) = updated[denomination, default: 0].addingReportingOverflow(count)
            guard count >= 0, !overflow else { throw InputValidation.Failure.outOfRange }
            updated[denomination] = sum
        }
        quantities = updated
    }

    mutating func remove(_ count: Int, denomination: TokenDenomination) throws {
        let owned = quantities[denomination, default: 0]
        guard count > 0, count <= owned else { throw InputValidation.Failure.outOfRange }
        quantities[denomination] = owned - count
    }
}
