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

//    let playSound: (String) -> SKAction = {
//        SKAction.playSoundFileNamed($0, waitForCompletion: false)
//    }
    
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
//            print("⚠️ MIDIEvent: \(midiEvent)")
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
                    case 16: // Torque
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
        makeSpawnPositionNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        let shakeMult = didShake ? -1.0 : 1.0
        r += (rotationSpeed - 5) * 0.01 * -1 * shakeMult
        tombolaSegments.forEach {
            $0.zRotation = r
        }
        
        if previousTime == .zero {
            previousTime = currentTime
        }
        
        if previousTime + noteFiringTimeWindow < currentTime {
            fire()
            noteCollection = []
            previousTime = currentTime
        }
        
        if isMotionEnabled, let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 2.0,
                                            dy: accelerometerData.acceleration.y * 2.0)
        }
        
//        noteDots.forEach {
//            let offScreenRight = $0.position.x > view?.scene?.frame.maxX ?? 0
//            let offScreenLeft = $0.position.x < 0
//            if $0.position.x
//            print("noteDot.position: \($0.position)")
//        }
        
        super.update(currentTime)
    }
    
    func fire() {
        noteCollection
            .forEach { [weak self] note in
                self?.midiHelper.sendNoteOn(UInt7(note))
            }
    }
}

final class NoteDot: SKShapeNode {
    
    let noteValue: Int
    
    init(radius: CGFloat, noteValue: Int, name: String, mass: CGFloat) {
        self.noteValue = noteValue
        
        super.init()
    
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        self.path = path
        self.name = name

        fillColor = .white
        strokeColor = .white
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.mass = mass
        physicsBody?.density = 0
        physicsBody?.friction = mass
        physicsBody?.restitution = 1
        physicsBody?.linearDamping = mass
        physicsBody?.angularDamping = mass
        physicsBody?.allowsRotation = true
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.categoryBitMask = PhysicsCategory.dot.bitMask
        physicsBody?.collisionBitMask = PhysicsCategory.tombola.bitMask
        physicsBody?.contactTestBitMask = PhysicsCategory.tombola.bitMask | PhysicsCategory.worldBoundary.bitMask
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private extension GameScene {

    func makeNoteDot(_ noteValue: Int) {
        let noteOccurances = noteDots.filter { $0.noteValue == noteValue }.count
        let noteDotName = "\(noteValue)-\(noteOccurances)" // example: 36-1 is the second note dot of 36
        let noteDot = NoteDot(radius: 5.0, noteValue: noteValue, name: noteDotName, mass: mass)
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
    
    func makeSpawnPositionNode() {
        let viewFrame = view?.frame ?? .zero
        let size = viewFrame.size.width * 0.03
        let halfSize = size * 0.5
        let path = CGMutablePath()

        path.move(to: CGPoint(x: -halfSize, y: 0))
        path.addLine(to: CGPoint(x: halfSize, y: 0))
        path.move(to: CGPoint(x: 0, y: -halfSize))
        path.addLine(to: CGPoint(x: 0, y: halfSize))
        
        let spawnPositionNode = SKShapeNode(path: path)
        spawnPositionNode.lineCap = .square
        spawnPositionNode.lineWidth = 1.0
        spawnPositionNode.strokeColor = .gray
        spawnPositionNode.position = view?.center ?? .zero
        
        let label = SKLabelNode(text: "spawn")
        label.fontColor = .gray
        label.fontName = "SFPro-Black"
        label.fontSize = 7.0
        label.position = CGPoint(x: label.position.x + 20.0, y: label.position.y - 4.0)
        spawnPositionNode.addChild(label)
        
//        spawnPositionNode.position = CGPoint(x: spawnPosition.x + 30, y: spawnPosition.y + 30)
//        label.posi
        
        addChild(spawnPositionNode)
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
            } else {
                print("⚠️")
            }
        default: // This is supposed to be case .worldBoundary: but this contact stuff isn't figured out properly
            print("⚠️ default contact case")
            let noteDot = noteDots.removeFirst(where: { $0.name == contact.bodyB.node?.name })
            noteDot?.removeFromParent()
        }
    }
}

extension Array {
    
    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {
            if let firstIndex = try firstIndex(where: predicate) {
                return self.remove(at: firstIndex)
            } else {
                return nil
            }
        }
        catch {
            throw error
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

func calculatePolygonCoordinates(_ numberOfSides: Int) -> [(Double, Double)] {
    var coordinates = [(Double, Double)]()
    for i in 0..<numberOfSides {
        let angle = 2 * Double.pi * Double(i) / Double(numberOfSides)
        let x = cos(angle)
        let y = sin(angle)
        coordinates.append((x, y))
    }
    return coordinates
}

func degreesToRadians(degrees: Double) -> Double {
    degrees * Double.pi / 180.0
}

// Function to rotate a point by a given angle (in radians) around the origin
func rotatePoint(point: CGPoint, angle: CGFloat) -> CGPoint {
    let rotatedX = point.x * cos(angle) - point.y * sin(angle)
    let rotatedY = point.x * sin(angle) + point.y * cos(angle)
    return CGPoint(x: rotatedX, y: rotatedY)
}

// Function to rotate two points around their center by a given angle (in radians)
func rotatePoints(point1: CGPoint, point2: CGPoint, angle: CGFloat) -> (CGPoint, CGPoint) {
    // Calculate the center point
    let centerX = (point1.x + point2.x) / 2
    let centerY = (point1.y + point2.y) / 2
    let center = CGPoint(x: centerX, y: centerY)
    
    // Translate points to origin
    let translatedPoint1 = CGPoint(x: point1.x - center.x, y: point1.y - center.y)
    let translatedPoint2 = CGPoint(x: point2.x - center.x, y: point2.y - center.y)
    
    // Rotate translated points
    let rotatedTranslatedPoint1 = rotatePoint(point: translatedPoint1, angle: angle)
    let rotatedTranslatedPoint2 = rotatePoint(point: translatedPoint2, angle: angle)
    
    // Translate rotated points back
    let rotatedPoint1 = CGPoint(x: rotatedTranslatedPoint1.x + center.x, y: rotatedTranslatedPoint1.y + center.y)
    let rotatedPoint2 = CGPoint(x: rotatedTranslatedPoint2.x + center.x, y: rotatedTranslatedPoint2.y + center.y)
    
    return (rotatedPoint1, rotatedPoint2)
}

func normalize(value: Double, min: Double, max: Double, newMin: Double, newMax: Double) -> Double {
    let normalizedValue = (value - min) / (max - min)
    let newValue = normalizedValue * (newMax - newMin) + newMin
    return newValue
}
