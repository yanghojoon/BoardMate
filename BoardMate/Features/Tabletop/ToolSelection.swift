//
//  ToolSelection.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation

enum ToolSelection: String, CaseIterable, Identifiable {
    case dice, hourglass, tokens

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dice: "주사위"
        case .hourglass: "모래시계"
        case .tokens: "토큰"
        }
    }

    var symbol: String {
        switch self {
        case .dice: "dice"
        case .hourglass: "hourglass"
        case .tokens: "circle.stack"
        }
    }
}
