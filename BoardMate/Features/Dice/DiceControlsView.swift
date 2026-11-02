//
//  DiceControlsView.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

import SwiftUI

struct DiceControlsView: View {
    let controller: DiceController
    private var dice: DiceState { controller.session.dice }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("주사위")
                Picker("주사위 개수", selection: Binding(
                    get: { dice.count },
                    set: { controller.setCount(String($0)) }
                )) {
                    ForEach(1...10, id: \.self) { Text("\($0)개").tag($0) }
                }
                .accessibilityIdentifier("dice.count")
                .disabled(!controller.canRoll)
                Spacer()
                Button(action: controller.roll) {
                    Label(dice.phase == .rolling ? "굴리는 중" : "굴리기", systemImage: "dice")
                        .foregroundStyle(BoardMateStyle.paper)
                }
                .buttonStyle(.borderedProminent)
                .tint(BoardMateStyle.ink)
                .disabled(!controller.canRoll)
                .accessibilityIdentifier("dice.roll")
            }
            Text(dice.result.isEmpty ? "아직 굴리지 않았습니다" :
                "직전 결과 · \(dice.result.count)개: " + dice.result.map(String.init).joined(separator: " · "))
                .font(.subheadline.monospacedDigit())
                .accessibilityIdentifier("dice.result")
                .accessibilityValue(dice.result.map(String.init).joined(separator: ","))
            Text(controller.inputError ?? "iPhone을 흔들어도 굴릴 수 있습니다")
                .font(.caption)
                .foregroundStyle(controller.inputError == nil ? BoardMateStyle.ink : .red)
                .accessibilityIdentifier("dice.hint")
        }
    }
}
