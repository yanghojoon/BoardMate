//
//  DiceControllerTests.swift
//  BoardMate
//
//  Created by 양호준 on 10/31/26.
//

@testable import BoardMate
import Foundation
import Observation
import RealityKit
import Synchronization
import Testing
import UIKit
import simd

@MainActor
struct DiceControllerTests {
    private func readySession(effects: SessionEffects = SessionEffects()) -> BoardMateSession {
        let session = BoardMateSession(effects: effects)
        session.setActive(true)
        session.navigation.select(.dice, reduceMotion: true)
        return session
    }

    @Test(arguments: [1, 2, 10]) func resultCountAndDuplicateInput(_ count: Int) throws {
        var draws = 0
        let session = readySession(effects: SessionEffects(nextDie: {
            draws += 1
            return (draws - 1) % 6 + 1
        }))
        let controller = DiceController(session: session)
        controller.setCount(String(count))
        controller.roll()
        let roll = try #require(session.dice.rollID)
        controller.roll() // The same command is used by button and motion callbacks.
        controller.setCount("3")
        #expect(draws == count)
        #expect(session.dice.result.count == count)
        #expect(session.dice.result.allSatisfy { (1...6).contains($0) })
        #expect(session.dice.count == count)
        #expect(session.dice.rollID == roll)
        #expect(!controller.canRoll)
        session.completeDiceRoll(id: roll)
        #expect(controller.canRoll)
    }

    @Test func invalidCountsKeepLastValidSetting() {
        let session = readySession()
        let controller = DiceController(session: session)
        for text in ["", "0", "-1", "1.5", "11"] {
            controller.setCount(text)
            #expect(session.dice.count == 2)
            #expect(controller.inputError != nil)
        }
        controller.setCount("10")
        #expect(controller.inputError == nil)
    }

    @Test func timerTicksPublishDiceOnlyWhenRollActuallyCompletes() throws {
        var now = Date(timeIntervalSince1970: 100)
        let session = BoardMateSession(clock: SessionClock(now: { now }))
        session.setActive(true)
        session.navigation.select(.dice, reduceMotion: true)
        let idleChanges = Mutex(0)
        withObservationTracking { _ = session.dice } onChange: { idleChanges.withLock { $0 += 1 } }
        for _ in 0..<10 { session.refreshTime() }
        #expect(idleChanges.withLock { $0 } == 0)
        _ = try session.rollDice()
        #expect(idleChanges.withLock { $0 } == 1)
        let rollingChanges = Mutex(0)
        withObservationTracking { _ = session.dice } onChange: { rollingChanges.withLock { $0 += 1 } }
        session.refreshTime()
        #expect(rollingChanges.withLock { $0 } == 0)
        now = now.addingTimeInterval(DiceState.rollDuration)
        session.refreshTime()
        #expect(rollingChanges.withLock { $0 } == 1)
        #expect(session.dice.phase == .idle)
    }

    @Test func inputRequiresActiveDiceAndSettledCamera() {
        var draws = 0
        let session = readySession(effects: SessionEffects(nextDie: { draws += 1; return 4 }))
        let controller = DiceController(session: session)
        for tool: ToolSelection? in [.hourglass, .tokens, nil] {
            session.navigation.select(tool, reduceMotion: true)
            controller.roll()
        }
        session.navigation.select(.dice)
        controller.roll()
        session.navigation.select(.dice, reduceMotion: true)
        session.setActive(false)
        controller.roll()
        #expect(draws == 0)
        #expect(session.dice.result.isEmpty)
    }

    @Test func deadlineCompletesAwayFromDiceWithoutAnimationCallback() throws {
        var now = Date(timeIntervalSince1970: 100)
        let session = BoardMateSession(clock: SessionClock(now: { now }),
                                       effects: SessionEffects(nextDie: { 5 }))
        session.setActive(true)
        session.navigation.select(.dice, reduceMotion: true)
        let roll = try session.rollDice()
        session.navigation.select(.tokens, reduceMotion: true)
        now = now.addingTimeInterval(DiceState.rollDuration - 0.01)
        session.refreshTime()
        #expect(session.dice.phase == .rolling)
        now = now.addingTimeInterval(0.02)
        session.refreshTime()
        #expect(session.dice.phase == .idle)
        #expect(session.dice.rollID == roll)
        #expect(session.dice.result == [5, 5])
        #expect(session.dice.deadline == nil)
    }

    @Test func inactivityAndLateCallbacksCannotLockOrReplaceAnotherRoll() throws {
        let session = readySession(effects: SessionEffects(nextDie: { 6 }))
        let first = try session.rollDice()
        session.setActive(false)
        #expect(session.dice.phase == .idle)
        #expect(session.dice.result == [6, 6])
        session.setActive(true)
        let second = try session.rollDice()
        session.completeDiceRoll(id: first)
        #expect(session.dice.phase == .rolling)
        #expect(session.dice.rollID == second)
    }

    @Test func nextCountImmediatelyUpdatesSceneAndPreservesPreviousNumericResult() async throws {
        let session = readySession(effects: SessionEffects(nextDie: { 3 }))
        let roll = try session.rollDice()
        session.completeDiceRoll(id: roll)
        try session.setDiceCount("5")
        #expect(session.dice.count == 5)
        #expect(session.dice.result == [3, 3])
        let scene = TabletopScene()
        await scene.showDice(session.dice, animated: false)
        let root = try #require(scene.root.findEntity(named: "dice"))
        #expect(root.children.count == 5)
        #expect(session.dice.displayedValues == [3, 3, 1, 1, 1])
        try session.setDiceCount("1")
        await scene.showDice(session.dice, animated: false)
        #expect(root.children.count == 1)
        #expect(session.dice.result == [3, 3])
        try session.setDiceCount("5")
        _ = try session.rollDice()
        #expect(session.dice.result == Array(repeating: 3, count: 5))
    }

    @Test func rollTrajectoriesLandOnCorrectFacesWithoutPenetratingTable() throws {
        let roll = UUID()
        for value in 1...6 {
            let start = Transform(scale: SIMD3(repeating: 0.53), translation: [0, 0.0265, 0])
            let final = DiceEntityFactory.restingOrientation(showing: value, index: value, rollID: roll)
            let motion = DiceEntityFactory.RollMotion(start: start, finalRotation: final)
            #expect((0.88...1.18).contains(motion.duration))
            #expect(simd_distance(motion.transform(at: 0).translation, start.translation) < 0.0001)
            for frame in 0...80 {
                let transform = motion.transform(at: Float(frame) / 60)
                let matrix = simd_float3x3(transform.rotation)
                let support: Float = 0.0265 * (abs(matrix[0].y) + abs(matrix[1].y) + abs(matrix[2].y))
                #expect(transform.translation.y >= support - 0.0001)
            }
            let landed = motion.transform(at: Float(DiceState.rollDuration))
            let normal = try #require(DiceEntityFactory.faceNormal(for: value))
            #expect(simd_distance(landed.rotation.act(normal), [0, 1, 0]) < 0.0001)
            #expect(simd_distance(landed.translation, start.translation) < 0.0001)
        }
    }

    @Test func tenRenderedDiceKeepMatchingTopFacesAndSeparatePositions() throws {
        let root = Entity()
        let values = [1, 2, 3, 4, 5, 6, 1, 2, 3, 4]
        DiceEntityFactory.arrange(values, on: root)
        #expect(root.children.count == 10)
        for (index, value) in values.enumerated() {
            let die = try #require(root.findEntity(named: "rolled-die-\(index)"))
            let normal = try #require(DiceEntityFactory.faceNormal(for: value))
            #expect(simd_length(die.orientation.act(normal) - SIMD3<Float>(0, 1, 0)) < 0.0001)
            #expect(die.children.filter { $0.name == "face-\(value)-pip" }.count == value)
            for other in root.children where other !== die {
                #expect(simd_distance(die.position, other.position) > 0.053)
                // Bounding spheres plus both dice's maximum sideways drift cannot intersect.
                #expect(simd_distance(die.position, other.position) > die.scale.x * 0.1 * sqrt(3) + 0.002)
            }
        }
        DiceEntityFactory.arrange([6], on: root)
        #expect(root.children.count == 1)
    }

    @Test func shakeBridgeOnlyForwardsEnabledShakeEvents() {
        let bridge = ShakeInputBridge.ShakeController()
        var events = 0
        bridge.onShake = { events += 1 }
        bridge.motionEnded(.motionShake, with: nil)
        #expect(events == 0)
        bridge.enabled = true
        bridge.motionEnded(.remoteControlPlay, with: nil)
        bridge.motionEnded(.motionShake, with: nil)
        #expect(events == 1)
        bridge.enabled = false
        bridge.motionEnded(.motionShake, with: nil)
        #expect(events == 1)
    }

    @Test func shakeResponderRemainsActiveAcrossRepeatedUpdates() {
        let controller = ShakeInputBridge.ShakeController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            controller.resignFirstResponder()
            window.isHidden = true
            window.rootViewController = nil
        }
        controller.enabled = true
        controller.updateResponder()
        #expect(controller.isFirstResponder)
        controller.updateResponder()
        #expect(controller.isFirstResponder)
        #expect(controller.inputView?.frame.height == 0)
        controller.enabled = false
        controller.updateResponder()
        #expect(!controller.isFirstResponder)
    }
}
