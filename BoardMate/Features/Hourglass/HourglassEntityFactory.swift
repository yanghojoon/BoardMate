//
//  HourglassEntityFactory.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import RealityKit
import simd

@MainActor
enum HourglassEntityFactory {
    static func make() -> Entity {
        let root = Entity()
        root.name = "hourglass"
        for height: Float in [0.012, 0.288] {
            let plate = ModelEntity(
                mesh: .generateCylinder(height: 0.024, radius: 0.086),
                materials: [EntityMaterials.brass]
            )
            plate.position.y = height
            root.addChild(plate)
        }
        for angle: Float in [0, .pi * 2 / 3, .pi * 4 / 3] {
            let pillar = ModelEntity(
                mesh: .generateCylinder(height: 0.252, radius: 0.0045),
                materials: [EntityMaterials.brass]
            )
            pillar.position = [cos(angle) * 0.076, 0.15, sin(angle) * 0.076]
            root.addChild(pillar)
        }
        for upper in [false, true] {
            let glass = ModelEntity(
                mesh: .generateCone(height: 0.116, radius: 0.060),
                materials: [EntityMaterials.glass]
            )
            glass.name = upper ? "glass-upper" : "glass-lower"
            glass.position.y = upper ? 0.208 : 0.092
            if upper { glass.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0]) }
            root.addChild(glass)
        }
        let upper = ModelEntity(mesh: .generateCone(height: 0.104, radius: 0.053), materials: [EntityMaterials.sand])
        upper.name = "sand-upper"
        upper.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        root.addChild(upper)
        let lower = ModelEntity(mesh: .generateCone(height: 0.104, radius: 0.053), materials: [EntityMaterials.sand])
        lower.name = "sand-lower"
        root.addChild(lower)
        let stream = ModelEntity(
            mesh: .generateCylinder(height: 0.12, radius: 0.0012),
            materials: [EntityMaterials.sand]
        )
        stream.name = "sand-stream"
        stream.position.y = 0.112
        root.addChild(stream)
        setProgress(0, on: root)
        return root
    }

    /// Visual-only normalized progress. No timer or session state is stored in the scene.
    static func setProgress(_ progress: Float, on root: Entity) {
        let fraction = progress.isFinite ? min(max(progress, 0), 1) : 0
        let remaining = pow(1 - fraction, 1 / Float(3))
        let accumulated = pow(fraction, 1 / Float(3))
        if let upper = root.findEntity(named: "sand-upper") {
            upper.isEnabled = fraction < 1
            upper.scale = SIMD3<Float>(repeating: max(remaining, 0.001))
            upper.position.y = 0.15 + 0.052 * remaining
        }
        if let lower = root.findEntity(named: "sand-lower") {
            lower.isEnabled = fraction > 0
            lower.scale = SIMD3<Float>(repeating: max(accumulated, 0.001))
            lower.position.y = 0.034 + 0.052 * accumulated
        }
        root.findEntity(named: "sand-stream")?.isEnabled = fraction > 0 && fraction < 1
    }

    static func update(_ state: HourglassState, on root: Entity, isActive: Bool, reduceMotion: Bool) {
        setProgress(Float(state.progress), on: root)
        root.findEntity(named: "sand-stream")?.isEnabled =
            state.phase == .running && state.remaining > 0 && isActive && !reduceMotion
    }
}
