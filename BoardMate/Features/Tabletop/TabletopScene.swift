//
//  TabletopScene.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import RealityKit
import UIKit
import simd

@MainActor
final class TabletopScene {
    let root = Entity()
    let camera = PerspectiveCamera()
    private var cameraAnimation: AnimationPlaybackController?
    private let diceRoot = Entity()
    private let hourglassRoot = HourglassEntityFactory.make()

    init() {
        root.name = "tabletop"
        let desk = ModelEntity(
            mesh: .generateBox(size: [1.7, 0.06, 1.3], cornerRadius: 0.025),
            materials: [SimpleMaterial(color: UIColor(red: 0.24, green: 0.12, blue: 0.065, alpha: 1),
                                       roughness: 0.72, isMetallic: false)]
        )
        desk.position.y = -0.03
        root.addChild(desk)
        // Narrow inset strips give the procedural walnut surface visible grain at both distances.
        for index in 0 ..< 28 {
            let grain = ModelEntity(
                mesh: .generateBox(size: [1.68, 0.0003, index.isMultiple(of: 3) ? 0.003 : 0.001]),
                materials: [SimpleMaterial(color: UIColor(red: 0.18, green: 0.085, blue: 0.04, alpha: 1),
                                           roughness: 0.85, isMetallic: false)]
            )
            grain.position = [0, 0.0001, Float(index) * 0.045 - 0.61]
            root.addChild(grain)
        }
        DiceEntityFactory.arrange([1, 1], on: diceRoot)
        addTool(diceRoot, tool: .dice, position: [-0.34, 0, 0.08], size: [0.42, 0.22, 0.30])
        let hourglass = hourglassRoot
        #if DEBUG
            if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "--hourglass-progress"),
               ProcessInfo.processInfo.arguments.indices.contains(index + 1),
               let progress = Float(ProcessInfo.processInfo.arguments[index + 1]) {
                HourglassEntityFactory.setProgress(progress, on: hourglass)
            }
        #endif
        addTool(hourglass, tool: .hourglass, position: [0, 0, -0.15], size: [0.23, 0.36, 0.23])
        addTool(TokenEntityFactory.make(), tool: .tokens, position: [0.33, 0, 0.08], size: [0.32, 0.12, 0.30])
        let light = DirectionalLight()
        light.light.color = UIColor(red: 1, green: 0.88, blue: 0.70, alpha: 1)
        light.light.intensity = 2400
        light.shadow = DirectionalLightComponent.Shadow(maximumDistance: 3)
        light.look(at: [0, 0, 0], from: [-0.5, 1.5, 0.8], relativeTo: nil)
        root.addChild(light)
        let fill = PointLight()
        fill.light.intensity = 180
        fill.light.attenuationRadius = 3
        fill.position = [0.7, 0.8, 0.4]
        root.addChild(fill)
        camera.camera.fieldOfViewInDegrees = 48
        camera.transform = cameraTransform(for: nil)
        root.addChild(camera)
    }

    func moveCamera(to tool: ToolSelection?, immediately: Bool) {
        cameraAnimation?.stop()
        let destination = cameraTransform(for: tool)
        if immediately {
            camera.transform = destination
        } else {
            cameraAnimation = camera.move(to: destination, relativeTo: root,
                                          duration: BoardMateStyle.cameraDuration, timingFunction: .easeInOut)
        }
    }

    func showDice(_ state: DiceState, animated: Bool) async {
        let values = state.displayedValues
        guard animated, state.phase == .rolling else {
            DiceEntityFactory.arrange(values, on: diceRoot, rollID: state.rollID)
            return
        }
        if diceRoot.children.count != values.count {
            DiceEntityFactory.arrange(Array(repeating: 1, count: values.count), on: diceRoot)
        }
        let dice = Array(diceRoot.children)
        let motions = dice.enumerated().map { index, die in
            DiceEntityFactory.RollMotion(start: die.transform, finalRotation:
                DiceEntityFactory.restingOrientation(showing: values[index], index: index, rollID: state.rollID))
        }
        let clock = ContinuousClock()
        let started = clock.now
        while !Task.isCancelled {
            let elapsed = started.duration(to: clock.now).components
            let seconds = Float(elapsed.seconds) + Float(elapsed.attoseconds) / 1e18
            for (die, motion) in zip(dice, motions) {
                die.transform = motion.transform(at: seconds)
            }
            if seconds >= Float(DiceState.rollDuration) { return }
            do { try await Task.sleep(for: .milliseconds(16)) } catch { return }
        }
    }

    func showHourglass(_ state: HourglassState, isActive: Bool, reduceMotion: Bool) {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--hourglass-progress") { return }
        #endif
        HourglassEntityFactory.update(state, on: hourglassRoot, isActive: isActive, reduceMotion: reduceMotion)
    }

    private func cameraTransform(for tool: ToolSelection?) -> Transform {
        let target: SIMD3<Float>
        let offset: SIMD3<Float>
        switch tool {
        case .dice:
            target = [-0.34, 0.06, 0.08]
            offset = [0.20, 0.35, 0.48]
        case .hourglass:
            target = [0, 0.15, -0.15]
            offset = [0.14, 0.15, 0.55]
        case .tokens:
            target = [0.33, 0.025, 0.08]
            offset = [0.04, 0.36, 0.30]
        case nil:
            target = [0, 0.04, 0]
            offset = [0, 1.15, 1.42]
        }
        let pose = PerspectiveCamera()
        pose.look(at: target, from: target + offset, relativeTo: nil)
        return pose.transform
    }

    private func addTool(_ entity: Entity, tool: ToolSelection, position: SIMD3<Float>, size: SIMD3<Float>) {
        entity.name = tool.rawValue
        entity.position = position
        // The root collision volume remains selectable even with zero player tokens.
        entity.components.set(CollisionComponent(shapes: [.generateBox(size: size).offsetBy(
            translation: [0, size.y / 2, 0])]))
        entity.components.set(InputTargetComponent())
        root.addChild(entity)
    }
}
