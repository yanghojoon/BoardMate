//
//  TokenEntityFactory.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import RealityKit
import UIKit

@MainActor
enum TokenEntityFactory {
    static let denominations = [1, 5, 10, 20, 50]

    /// Display specimens stay separate from the future session's zero initial inventory.
    static func make() -> Entity {
        let root = Entity()
        root.name = "tokens"
        let tray = ModelEntity(
            mesh: .generateBox(size: [0.25, 0.014, 0.19], cornerRadius: 0.012),
            materials: [EntityMaterials.walnut]
        )
        tray.name = "token-selection-tray"
        tray.position.y = 0.007
        root.addChild(tray)
        let lining = ModelEntity(
            mesh: .generateBox(size: [0.232, 0.003, 0.172], cornerRadius: 0.009),
            materials: [EntityMaterials.felt]
        )
        lining.position.y = 0.015
        root.addChild(lining)
        let positions: [SIMD3<Float>] = [
            [-0.077, 0.022, -0.043], [0, 0.022, -0.043], [0.077, 0.022, -0.043],
            [-0.039, 0.022, 0.042], [0.039, 0.022, 0.042]
        ]
        for (index, value) in denominations.enumerated() {
            let coin = makeCoin(value: value)
            coin.position = positions[index]
            root.addChild(coin)
        }
        return root
    }

    static func makeCoin(value: Int) -> Entity {
        let coin = Entity()
        coin.name = "specimen-\(value)"
        let rim = ModelEntity(mesh: .generateCylinder(height: 0.008, radius: 0.034), materials: [EntityMaterials.brass])
        coin.addChild(rim)
        let face = ModelEntity(
            mesh: .generateCylinder(height: 0.001, radius: 0.029),
            materials: [EntityMaterials.ivory]
        )
        face.position.y = 0.0044
        coin.addChild(face)
        let mesh = MeshResource.generateText(
            String(value),
            extrusionDepth: 0.0006,
            font: .boldSystemFont(ofSize: 0.024)
        )
        let label = ModelEntity(mesh: mesh, materials: [EntityMaterials.ink])
        let center = label.visualBounds(relativeTo: label).center
        let text = Entity()
        label.position = -center
        text.addChild(label)
        text.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        text.position.y = 0.0052
        coin.addChild(text)
        return coin
    }
}
