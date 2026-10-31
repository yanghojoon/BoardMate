//
//  TabletopView.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import RealityKit
import SwiftUI

struct TabletopView: View {
    let session: BoardMateSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene = TabletopScene()
    @State private var diceController: DiceController

    init(session: BoardMateSession) {
        self.session = session
        _diceController = State(initialValue: DiceController(session: session))
    }

    private var coordinator: CameraCoordinator { session.navigation }

    private var usesReducedMotion: Bool {
        #if DEBUG
            reduceMotion || ProcessInfo.processInfo.arguments.contains("--reduce-motion")
        #else
            reduceMotion
        #endif
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 12)
            RealityView { content in
                content.camera = .virtual
                content.add(scene.root)
            }
            .realityViewCameraControls(.none)
            .gesture(TapGesture().targetedToAnyEntity().onEnded { value in
                var entity: Entity? = value.entity
                while let current = entity {
                    if let tool = ToolSelection(rawValue: current.name) {
                        coordinator.select(tool, reduceMotion: usesReducedMotion)
                        break
                    }
                    entity = current.parent
                }
            })
            .accessibilityLabel("월넛 책상의 세 가지 보드게임 도구")
            .overlay(alignment: .bottom) {
                Text(navigationHint)
                    .font(.caption)
                    .padding(10)
                    .background(BoardMateStyle.paper.opacity(0.92), in: Capsule())
                    .padding(.bottom, 16)
                    .accessibilityIdentifier("tabletop.transition")
                    .accessibilityValue(coordinator.isTransitioning ? "moving" : "idle")
            }
            controls
        }
        .foregroundStyle(BoardMateStyle.ink)
        .background(BoardMateStyle.paper)
        .background {
            ShakeInputBridge(enabled: diceController.canRoll, onShake: diceController.roll)
                .allowsHitTesting(false)
        }
        .task(id: session.dice) {
            await scene.showDice(session.dice, animated: !usesReducedMotion)
        }
        .task(id: coordinator.requestID) {
            let request = coordinator.requestID
            scene.moveCamera(to: coordinator.selectedTool, immediately: coordinator.reducesMotion)
            guard coordinator.isTransitioning else { return }
            do {
                try await Task.sleep(for: .seconds(BoardMateStyle.cameraDuration))
                try Task.checkCancellation()
                coordinator.complete(requestID: request)
            } catch {
                // A newer selection owns camera completion.
            }
        }
    }

    private var navigationHint: String {
        if coordinator.isTransitioning {
            return "시점을 옮기는 중"
        }
        if coordinator.selectedTool != nil {
            return "다른 도구를 고르거나 책상으로 돌아가세요"
        }
        return "도구를 선택해 가까이 살펴보세요"
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BOARDMATE").font(.caption.weight(.semibold)).tracking(3)
                if let tool = coordinator.selectedTool {
                    Text(tool.title)
                        .font(.system(.title, design: .serif, weight: .semibold))
                }
            }
            .frame(height: 60, alignment: .topLeading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("tabletop.selection")
            .accessibilityValue(coordinator.selectedTool?.rawValue ?? "overview")
            Spacer()
            Button {
                coordinator.select(nil, reduceMotion: usesReducedMotion)
            } label: {
                Label("책상", systemImage: "square.grid.2x2")
            }
            .accessibilityIdentifier("select.overview")
        }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach(ToolSelection.allCases) { tool in
                    Button {
                        coordinator.select(tool, reduceMotion: usesReducedMotion)
                    } label: {
                        Label(tool.title, systemImage: tool.symbol)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(coordinator.selectedTool == tool
                                        ? BoardMateStyle.brass.opacity(0.22) : .white.opacity(0.6),
                                        in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("select.\(tool.rawValue)")
                    .accessibilityAddTraits(coordinator.selectedTool == tool ? .isSelected : [])
                }
            }
            Group {
                switch coordinator.selectedTool {
                case .dice: DiceControlsView(controller: diceController)
                case .hourglass: Text("황동 모래시계 · 3분 대기")
                case .tokens: Text("보유 토큰 0개 · 동전은 단위 확인용 표본입니다")
                case nil: Text("주사위 · 모래시계 · 토큰")
                }
            }
            .font(.footnote)
            .multilineTextAlignment(.center)
        }
        .padding(20)
    }
}
