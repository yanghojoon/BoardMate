//
//  CameraCoordinator.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Observation

@MainActor @Observable
final class CameraCoordinator {
    private(set) var selectedTool: ToolSelection?
    private(set) var isTransitioning = false
    private(set) var requestID = 0
    private(set) var reducesMotion = false

    var canExecute: Bool { selectedTool != nil && !isTransitioning }

    @discardableResult
    func select(_ tool: ToolSelection?, reduceMotion: Bool = false) -> Int {
        requestID += 1
        selectedTool = tool
        reducesMotion = reduceMotion
        isTransitioning = !reduceMotion
        return requestID
    }

    func complete(requestID: Int) {
        guard self.requestID == requestID else { return }
        isTransitioning = false
    }

    @discardableResult
    func performToolAction(_ action: (ToolSelection) -> Void) -> Bool {
        guard canExecute, let selectedTool else { return false }
        action(selectedTool)
        return true
    }
}
