//
//  DiceEntityFactory.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

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
