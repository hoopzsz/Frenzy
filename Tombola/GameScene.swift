//
//  GameScene.swift
//  Line Square Dot
//
//  Created by Daniel Hooper on 2018-09-20.
//  Copyright © 2018 danielhooper. All rights reserved.
//

import CoreMotion
import MIDIKitIO
import SpriteKit

final class GameScene: SKScene, ObservableObject {
    
    var noteCollection: Set<Int> = []
    
    var noteFiringTimeWindow = 0.1
    var previousTime: TimeInterval = .zero
    
    let bpm = 120.0
    
    var didShake = false {
        didSet {
//            print("⚠️ Shake detected: \(didShake)")
//            noteDots.forEach {
//                if let physicsBody = $0.physicsBody {
//                    physicsBody.velocity = CGVector(dx: physicsBody.velocity.dx * -1,
//                                                    dy: physicsBody.velocity.dy * -1)
//                }
//            }
        }
    }
    
    @Published var gravity: CGFloat = 3.3 {
        didSet {
            setGravity(gravity)
        }
    }
    
    func setGravity(_ gravity: CGFloat) {
        let normalizedGravity = (gravity - 3) * -1 // normalize to -3 to 3.0, then reverse
        physicsWorld.gravity = CGVector(dx: 0.0, dy: normalizedGravity)
    }
    
    @Published var isMotionEnabled: Bool = false {
        didSet {
            print("⚠️ isMotionEnabled didSet: \(isMotionEnabled)")
            if isMotionEnabled {
                // Handled by update method
            } else {
                setGravity(gravity)
            }
        }
    }
    
    @Published var mass: CGFloat = 0.0 {
        didSet {
            noteDots.forEach {
                $0.physicsBody?.linearDamping = mass
                $0.physicsBody?.angularDamping = mass
            }
        }
    }
    
    var keyPress: Int? {
        didSet {
            if let keyPress = keyPress {
                makeNoteDot(keyPress)
            }
        }
    }
    
    var r: CGFloat = 0
    
    @Published var rotationSpeed: CGFloat = 5.5
    
    @Published var segmentOffset: CGFloat = 0.0 {
        didSet {
            makeTombolaSegments() // we have to redraw new points
        }
    }

    @Published var scale: CGFloat = 0.75 {
        didSet {
            tombolaSegments.forEach {
                $0.xScale = scale
                $0.yScale = scale
            }
        }
    }
    
    @Published var numberOfSides: CGFloat = 6.0 {
        didSet {
            makeTombolaSegments()
        }
    }
        
    private let motionManager = CMMotionManager()
    
    @Published var noteDots: [NoteDot] = []
    
    private var tombolaSegments: [SKShapeNode] = []

    private let midiManager = ObservableMIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    private let midiHelper = MIDIHelper()
    
    @Published var spawnPosition: CGPoint = .zero

    override init() {
        super.init(size: .zero)
        
        midiHelper.setup(midiManager: midiManager)
        
        midiHelper.didReceiveMIDIEvent = { [weak self] midiEvent in
            DispatchQueue.main.sync {
                switch midiEvent {
                case .noteOn(let noteOn):
                    self?.keyPress = Int(noteOn.note.number)
                case .cc(let cc):
                    let value = Double(cc.value.midi2Value)
                    switch cc.controller.number {
                    case 13: // Gravity
                        let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 0.1, newMax: 1.5)
                        self?.gravity = normalizedValue
                    case 14: // Mass
                        let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 0.0, newMax: 100.0)
                        self?.mass = normalizedValue
                    case 15: // Scale
                        let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.2, newMax: 2.0)
                        self?.scale = normalizedValue
                    case 16: // Torquex
                        let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 10.0)
                        self?.rotationSpeed = normalizedValue
                    case 17: // Spread
                        let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 180.0)
                        self?.segmentOffset = normalizedValue
                    case 18: // Vertices
                        let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 2.0, newMax: 13.0)
                        self?.numberOfSides = normalizedValue
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }

        scaleMode = .aspectFit
        backgroundColor = .black
        
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 2.0
        setGravity(gravity)
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        motionManager.startAccelerometerUpdates()

        view.backgroundColor = backgroundColor
        view.ignoresSiblingOrder = true

        physicsBody?.categoryBitMask = PhysicsCategory.worldBoundary.bitMask
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.bitMask
        physicsBody = SKPhysicsBody(edgeLoopFrom: view.frame.insetBy(dx: -6.0, dy: -6.0)) // dot radius minus 1

        makeTombolaSegments()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        if previousTime == .zero {
            previousTime = currentTime
        }
        
        r += (rotationSpeed - 5) * 0.01 * -1
        tombolaSegments.forEach {
            $0.zRotation = r
        }

        // This allows us to 'quantize' our note firing events
        // Most importantly, it will concatenate note firing events that happen very close to eachother
        // which may produce unpleasent sounding results
        if previousTime + noteFiringTimeWindow < currentTime {
            fire()
            noteCollection = []
            previousTime = currentTime
        }
        
        if isMotionEnabled, let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 2.0,
                                            dy: accelerometerData.acceleration.y * 2.0)
        }

        super.update(currentTime)
    }
    
    func fire() {
        noteCollection
            .forEach { [weak self] note in
                self?.midiHelper.sendNoteOn(UInt7(note))
            }
    }
}


private extension GameScene {

    func makeNoteDot(_ noteValue: Int) {
        let noteOccurances = noteDots.filter { $0.noteValue == noteValue }.count
        let noteDotName = "\(noteValue)-\(noteOccurances)" // example: 36-1 is the second note dot of 36
        let noteDot = NoteDot(radius: 5.0, noteValue: noteValue, mass: mass)
        noteDot.position = CGPoint(x: view?.frame.midX ?? 0.0, y: view?.frame.midY ?? 0.0)
        noteDots.append(noteDot)
        addChild(noteDot)
    }
    
    func makeTombolaSegments() {
        self.tombolaSegments.forEach {
            $0.removeFromParent()
        }
        self.tombolaSegments = []
        let numberOfSides = Int(self.numberOfSides)
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
        
//        let path = CGMutablePath()
        let points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
                
//        let colors: [UIColor] = [.red, .blue, .green, .gray, .yellow, .purple, .systemPink ]
        var lookaheadIndex = 1
        for point in points {
            if lookaheadIndex == points.count {
                lookaheadIndex = 0
            }
            let path = CGMutablePath()
            let rotatedPoints = rotatePoints(point1: point, point2: points[lookaheadIndex],
                                             angle: degreesToRadians(degrees: segmentOffset))
            path.move(to: rotatedPoints.0)
            path.addLine(to: rotatedPoints.1)
            let segmentNode = SKShapeNode(path: path)
            segmentNode.lineWidth = 3.0
            segmentNode.strokeColor = .orange
            segmentNode.physicsBody = SKPhysicsBody(edgeFrom: rotatedPoints.0, to: rotatedPoints.1)
            segmentNode.physicsBody?.affectedByGravity = false
            segmentNode.physicsBody?.pinned = true
            segmentNode.physicsBody?.mass = 1.0
            segmentNode.physicsBody?.density = 1.0
            segmentNode.physicsBody?.restitution = 1.0
            segmentNode.physicsBody?.allowsRotation = true
            segmentNode.physicsBody?.categoryBitMask = PhysicsCategory.tombola.bitMask
            segmentNode.physicsBody?.collisionBitMask = PhysicsCategory.dot.bitMask
            segmentNode.physicsBody?.contactTestBitMask = PhysicsCategory.dot.bitMask
            segmentNode.physicsBody?.usesPreciseCollisionDetection = true
            segmentNode.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
            segmentNode.xScale = scale
            segmentNode.yScale = scale
            self.tombolaSegments.append(segmentNode)
            addChild(segmentNode)
            lookaheadIndex += 1
        }
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
//        if contact.collisionImpulse > 500 {
            // Do something for high impact
//        }

        // This isn't correct, but it works.
        let dotBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
        
        // This is working, but doesn't make sense. dotBody isn't really the dot
        switch dotBody.categoryOfContact() {
        case .tombola:
            guard contact.collisionImpulse > 1.0 else { return }
            if let noteDotNode = contact.bodyB.node as? NoteDot {
                noteCollection.insert(noteDotNode.noteValue)
            }
        // This is supposed to be case .worldBoundary: but this contact stuff isn't figured out properly
        default:
            // TODO use UUID to remove the correct nodes
            let noteDot = noteDots.removeFirst(where: { $0.name == contact.bodyB.node?.name })
            noteDot?.removeFromParent()
        }
    }
}

enum PhysicsCategory: CaseIterable {
    case dot, tombola, worldBoundary

    var bitMask: UInt32 {
        switch self {
        case .dot:
            0x1 << 0
        case .tombola:
            0x1 << 1
        case .worldBoundary:
            0x1 << 2
        }
    }
}

extension SKPhysicsBody {
    
    func categoryOfContact() -> PhysicsCategory? {
        PhysicsCategory.allCases.first { categoryBitMask & $0.bitMask != 0 }
    }
}

import SwiftUI

#Preview {
    ContentView()
}
