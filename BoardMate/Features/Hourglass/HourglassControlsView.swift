//
//  HourglassControlsView.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import SwiftUI

struct HourglassControlsView: View {
    let controller: HourglassController
    @State private var minutes: String
    @State private var seconds: String
    @FocusState private var editing: String?

    init(controller: HourglassController) {
        self.controller = controller
        let duration = Int(controller.session.hourglass.duration)
        _minutes = State(initialValue: String(duration / 60))
        _seconds = State(initialValue: String(duration % 60))
    }

    private var timer: HourglassState { controller.session.hourglass }
    private var remainingSeconds: Int { Int(ceil(timer.remaining)) }
    private var phase: String {
        switch timer.phase {
        case .idle: "대기"
        case .running: "실행 중"
        case .finished: "종료"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60))
                    .font(.system(.title, design: .serif).monospacedDigit())
                    .accessibilityLabel("남은 시간")
                    .accessibilityValue(String(remainingSeconds))
                    .accessibilityIdentifier("hourglass.remaining")
                Text(phase)
                    .accessibilityIdentifier("hourglass.phase")
                    .accessibilityValue(String(describing: timer.phase))
                Spacer()
                Button("리셋") {
                    editing = nil
                    controller.reset()
                    restoreInputs()
                }
                .disabled(!controller.canReset)
                .accessibilityIdentifier("hourglass.reset")
                Button("시작") {
                    editing = nil
                    controller.start()
                }
                .buttonStyle(.borderedProminent)
                .tint(BoardMateStyle.ink)
                .foregroundStyle(BoardMateStyle.paper)
                .disabled(!controller.canStart)
                .accessibilityIdentifier("hourglass.start")
            }
            HStack {
                timeField("분", text: $minutes, identifier: "hourglass.minutes")
                timeField("초", text: $seconds, identifier: "hourglass.seconds")
                Button("설정 적용") {
                    editing = nil
                    controller.configure(minutes: minutes, seconds: seconds)
                }
                .disabled(!controller.canConfigure)
                .accessibilityIdentifier("hourglass.apply")
            }
            Text(controller.inputError ?? "설정을 적용한 뒤 시작하세요 · 이탈 중에도 시간은 흐릅니다")
                .font(.caption)
                .foregroundStyle(controller.inputError == nil ? BoardMateStyle.ink : .red)
                .accessibilityIdentifier("hourglass.hint")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("완료") { editing = nil }
            }
        }
    }

    private func timeField(_ label: String, text: Binding<String>, identifier: String) -> some View {
        HStack(spacing: 4) {
            TextField(label, text: text)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 52)
                .focused($editing, equals: identifier)
                .disabled(!controller.canConfigure)
                .accessibilityLabel(label)
                .accessibilityIdentifier(identifier)
            Text(label)
        }
    }

    private func restoreInputs() {
        minutes = String(Int(timer.duration) / 60)
        seconds = String(Int(timer.duration) % 60)
    }
}
