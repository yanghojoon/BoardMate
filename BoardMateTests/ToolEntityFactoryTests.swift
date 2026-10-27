//
//  ToolEntityFactoryTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/27/26.
//

@testable import BoardMate
import RealityKit
import simd
import XCTest

@MainActor
final class ToolEntityFactoryTests: XCTestCase {
    func testEveryDiceFaceHasMatchingPipsAndRotatesUpward() throws {
        let root = DiceEntityFactory.make()
        let die = try XCTUnwrap(root.findEntity(named: "die-body"))

        for value in 1 ... 6 {
            let normal = try XCTUnwrap(DiceEntityFactory.faceNormal(for: value))
            let orientation = try XCTUnwrap(DiceEntityFactory.orientation(showing: value))
            let opposite = try XCTUnwrap(DiceEntityFactory.faceNormal(for: 7 - value))
            let pips = die.children.filter { $0.name == "face-\(value)-pip" }

            XCTAssertEqual(pips.count, value)
            XCTAssertLessThan(simd_length(orientation.act(normal) - SIMD3<Float>(0, 1, 0)), 0.0001)
            XCTAssertLessThan(simd_length(normal + opposite), 0.0001)
            for pip in pips {
                XCTAssertEqual(simd_dot(pip.position, normal), 0.0498, accuracy: 0.0001)
            }
        }

        XCTAssertNil(DiceEntityFactory.faceNormal(for: 0))
        XCTAssertNil(DiceEntityFactory.orientation(showing: 7))
    }

    func testHourglassProgressPreservesVolumeAndEndpointVisibility() throws {
        let root = HourglassEntityFactory.make()
        let upper = try XCTUnwrap(root.findEntity(named: "sand-upper"))
        let lower = try XCTUnwrap(root.findEntity(named: "sand-lower"))
        let stream = try XCTUnwrap(root.findEntity(named: "sand-stream"))

        for progress: Float in [0, 0.5, 1] {
            HourglassEntityFactory.setProgress(progress, on: root)

            XCTAssertEqual(upper.isEnabled, progress < 1)
            XCTAssertEqual(lower.isEnabled, progress > 0)
            XCTAssertEqual(stream.isEnabled, progress > 0 && progress < 1)
            let upperVolume = upper.isEnabled ? pow(upper.scale.x, 3) : 0
            let lowerVolume = lower.isEnabled ? pow(lower.scale.x, 3) : 0
            XCTAssertEqual(upperVolume, 1 - progress, accuracy: 0.0001)
            XCTAssertEqual(lowerVolume, progress, accuracy: 0.0001)
            XCTAssertEqual(upperVolume + lowerVolume, 1, accuracy: 0.0001)
            XCTAssertNotNil(root.findEntity(named: "glass-upper"))
            XCTAssertNotNil(root.findEntity(named: "glass-lower"))
        }
    }

    func testHourglassClampsInvalidVisualProgress() throws {
        let root = HourglassEntityFactory.make()
        let upper = try XCTUnwrap(root.findEntity(named: "sand-upper"))
        let lower = try XCTUnwrap(root.findEntity(named: "sand-lower"))

        for progress: Float in [-1, .nan, .infinity] {
            HourglassEntityFactory.setProgress(progress, on: root)
            XCTAssertTrue(upper.isEnabled)
            XCTAssertFalse(lower.isEnabled)
            XCTAssertEqual(upper.scale.x, 1, accuracy: 0.0001)
        }

        HourglassEntityFactory.setProgress(2, on: root)
        XCTAssertFalse(upper.isEnabled)
        XCTAssertTrue(lower.isEnabled)
        XCTAssertEqual(lower.scale.x, 1, accuracy: 0.0001)
    }

    func testTokenTrayRemainsWhenNoCoinsAreDisplayed() throws {
        let root = TokenEntityFactory.make()
        let tray = try XCTUnwrap(root.findEntity(named: "token-selection-tray"))

        XCTAssertEqual(TokenEntityFactory.denominations, [1, 5, 10, 20, 50])
        for value in TokenEntityFactory.denominations {
            let specimen = try XCTUnwrap(root.findEntity(named: "specimen-\(value)"))
            specimen.removeFromParent()
        }

        XCTAssertTrue(tray.parent === root)
        XCTAssertTrue(tray.isEnabled)
        XCTAssertNotNil(tray.components[ModelComponent.self])
        XCTAssertTrue(root.children.allSatisfy { !$0.name.hasPrefix("specimen-") })
    }
}
