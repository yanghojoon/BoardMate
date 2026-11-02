//
//  ShakeInputBridge.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import SwiftUI
import UIKit

struct ShakeInputBridge: UIViewControllerRepresentable {
    var enabled: Bool
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeController { ShakeController() }

    func updateUIViewController(_ controller: ShakeController, context: Context) {
        controller.onShake = onShake
        let changed = controller.enabled != enabled
        controller.enabled = enabled
        if changed { controller.updateResponder() }
    }

    static func dismantleUIViewController(_ controller: ShakeController, coordinator: ()) {
        controller.enabled = false
        controller.onShake = nil
        controller.resignFirstResponder()
    }

    final class ShakeController: UIViewController {
        var enabled = false
        var onShake: (() -> Void)?
        override var canBecomeFirstResponder: Bool { enabled }
        // This responder consumes motion only; it must never request a software keyboard.
        override var inputView: UIView? { UIView(frame: .zero) }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            updateResponder()
        }

        func updateResponder() {
            if enabled, !isFirstResponder, viewIfLoaded?.window != nil {
                becomeFirstResponder()
            } else if !enabled, isFirstResponder {
                resignFirstResponder()
            }
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if enabled, motion == .motionShake {
                onShake?()
            } else {
                super.motionEnded(motion, with: event)
            }
        }
    }
}
