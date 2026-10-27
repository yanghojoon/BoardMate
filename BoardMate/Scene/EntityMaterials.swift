//
//  EntityMaterials.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

import RealityKit
import UIKit

@MainActor
enum EntityMaterials {
    static let ivory = SimpleMaterial(
        color: UIColor(red: 0.91, green: 0.85, blue: 0.70, alpha: 1),
        roughness: 0.48,
        isMetallic: false
    )
    static let ink = SimpleMaterial(
        color: UIColor(red: 0.12, green: 0.09, blue: 0.06, alpha: 1),
        roughness: 0.8,
        isMetallic: false
    )
    static let brass = SimpleMaterial(
        color: UIColor(red: 0.64, green: 0.43, blue: 0.19, alpha: 1),
        roughness: 0.42,
        isMetallic: true
    )
    static let sand = SimpleMaterial(
        color: UIColor(red: 0.84, green: 0.65, blue: 0.37, alpha: 1),
        roughness: 0.95,
        isMetallic: false
    )
    static let felt = SimpleMaterial(
        color: UIColor(red: 0.13, green: 0.20, blue: 0.17, alpha: 1),
        roughness: 1,
        isMetallic: false
    )
    static let walnut = SimpleMaterial(
        color: UIColor(red: 0.23, green: 0.12, blue: 0.065, alpha: 1),
        roughness: 0.65,
        isMetallic: false
    )

    static var glass: PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.81, green: 0.92, blue: 0.91, alpha: 1))
        material.roughness = .init(floatLiteral: 0.12)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.16))
        material.faceCulling = .back
        return material
    }
}
