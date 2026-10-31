//
//  HapticClient.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import UIKit

@MainActor
enum HapticClient {
    static func timerFinished() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
