//
//  DiceEntityFactory.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import Foundation
import RealityKit
import simd

@MainActor
enum DiceEntityFactory {
    /// Right-handed local axes; opposing faces sum to seven. Pivot is the die center.
    static func faceNormal(for value: Int) -> SIMD3<Float>? {
        switch value {
        case 1: [0, 1, 0]
        case 2: [0, 0, 1]
        case 3: [1, 0, 0]
        case 4: [-1, 0, 0]
        case 5: [0, 0, -1]
        case 6: [0, -1, 0]
        default: nil
        }
    }

    static func orientation(showing value: Int) -> simd_quatf? {
        guard let normal = faceNormal(for: value) else { return nil }
        return simd_quatf(from: normal, to: SIMD3<Float>(0, 1, 0))
    }

    static func make() -> Entity {
        let root = Entity()
        root.name = "dice"
        let die = ModelEntity(mesh: .generateBox(size: 0.10, cornerRadius: 0.012), materials: [EntityMaterials.ivory])
        die.name = "die-body"
        die.position.y = 0.05
        root.addChild(die)
        for value in 1 ... 6 {
            guard let normal = faceNormal(for: value) else { continue }
            let rotation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: normal)
            for point in pipPositions(for: value) {
                let pip = ModelEntity(
                    mesh: .generateCylinder(height: 0.0008, radius: 0.006),
                    materials: [EntityMaterials.ink]
                )
                pip.name = "face-\(value)-pip"
                pip.orientation = rotation
                pip.position = rotation.act(SIMD3<Float>(point.x, 0.0498, point.y))
                die.addChild(pip)
            }
        }
        return root
    }

    /// Reuses the detailed ivory die and its face mapping for each result.
    static func arrange(_ values: [Int], on root: Entity, rollID: UUID? = nil) {
        for child in Array(root.children) { child.removeFromParent() }
        let template = make()
        guard let body = template.findEntity(named: "die-body") else { return }
        for (index, value) in values.enumerated() {
            let die = body.clone(recursive: true)
            die.name = "rolled-die-\(index)"
            die.scale = SIMD3(repeating: 0.46)
            die.position = position(for: index, count: values.count)
            die.orientation = restingOrientation(showing: value, index: index, rollID: rollID)
            root.addChild(die)
        }
    }

    static func restingOrientation(showing value: Int, index: Int, rollID: UUID?) -> simd_quatf {
        let yaw = rollID.map { Float($0.uuid.0) * 0.07 + Float(index) * 2.39996 } ?? 0
        return simd_quatf(angle: yaw, axis: [0, 1, 0]) * (orientation(showing: value) ?? simd_quatf())
    }

    static func position(for index: Int, count: Int) -> SIMD3<Float> {
        let columns = min(count, 5)
        let row = index / columns
        let rowCount = min(columns, count - row * columns)
        return [Float(index % columns) * 0.082 - Float(rowCount - 1) * 0.041,
                0.023, Float(row) * 0.09 - (count > 5 ? 0.045 : 0)]
    }

    struct RollMotion {
        let start: Transform
        let finalRotation: simd_quatf
        let axis: SIMD3<Float>
        let turns: Float
        let duration: Float
        let height: Float
        let drift: SIMD3<Float>

        init(start: Transform, finalRotation: simd_quatf) {
            self.start = start
            let direction = Float.random(in: -.pi ... .pi)
            axis = simd_normalize(SIMD3<Float>(cos(direction), Float.random(in: -0.6...0.6), sin(direction)))
            turns = Float(Int.random(in: 2...3)) * 2 * .pi
            duration = Float.random(in: 0.88...1.18)
            height = Float.random(in: 0.055...0.105)
            drift = [Float.random(in: -0.001...0.001), 0, Float.random(in: -0.001...0.001)]
            self.finalRotation = finalRotation
        }

        func transform(at elapsed: Float) -> Transform {
            let progress = min(max(elapsed / duration, 0), 1)
            // Resolve the result during the first flight, before the die touches the table.
            // Whole turns preserve the starting pose and decay to zero without a late correction.
            let flightProgress = min(progress / 0.5, 1)
            let alignment = flightProgress * flightProgress * (3 - 2 * flightProgress)
            let spin = turns * pow(1 - flightProgress, 3)
            let base = simd_slerp(start.rotation, finalRotation, alignment)
            let rock: Float
            if progress < 0.5 {
                rock = 0
            } else if progress < 0.75 {
                let flight = (progress - 0.5) / 0.25
                rock = 0.12 * sin(flight * .pi) * sin(flight * .pi)
            } else {
                let flight = (progress - 0.75) / 0.25
                rock = -0.035 * sin(flight * .pi) * sin(flight * .pi)
            }
            let rotation = simd_quatf(angle: spin + rock, axis: axis) * base
            // Three progressively smaller ballistic arcs with only minor rocking after contact.
            let bounce: Float
            if progress < 0.5 {
                let flight = progress / 0.5
                bounce = height * 4 * flight * (1 - flight)
            } else if progress < 0.75 {
                let flight = (progress - 0.5) / 0.25
                bounce = height * 0.25 * 4 * flight * (1 - flight)
            } else {
                let flight = (progress - 0.75) / 0.25
                bounce = height * 0.05 * 4 * flight * (1 - flight)
            }
            let matrix = simd_float3x3(rotation)
            let support = 0.05 * start.scale.x * (abs(matrix[0].y) + abs(matrix[1].y) + abs(matrix[2].y))
            let travel = sin(flightProgress * .pi)
            var position = start.translation + drift * travel * travel
            position.y = max(start.translation.y + bounce, support)
            return Transform(scale: start.scale, rotation: rotation, translation: position)
        }
    }

    private static func pipPositions(for value: Int) -> [SIMD2<Float>] {
        let edge: Float = 0.023
        let diagonal: [SIMD2<Float>] = [[-edge, -edge], [edge, edge]]
        let corners: [SIMD2<Float>] = diagonal + [[-edge, edge], [edge, -edge]]
        switch value {
        case 1: return [.zero]
        case 2: return diagonal
        case 3: return diagonal + [.zero]
        case 4: return corners
        case 5: return corners + [.zero]
        default: return corners + [[-edge, 0], [edge, 0]]
        }
    }
}
