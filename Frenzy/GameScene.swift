//
//  GameScene.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-13.
//  Copyright © 2024 danielhooper. All rights reserved.
//

import CoreMotion
import MIDIKitIO
import SpriteKit

final class GameScene: SKScene, ObservableObject {
    
    @Published var midiChannelOutput: Int = 0 {
        didSet {
            midiHelper.outputChannel = UInt4(midiChannelOutput)
        }
    }
    
    @Published var midiChannelInput: Int = 0 {
        didSet {
            midiHelper.inputChannel = midiChannelInput
        }
    }
    
    @Published var isVelocityFixed: Bool = true
    
    @Published var globalTintColor: Color = .orange {
        didSet {
            tombolaSegments.forEach {
                $0.strokeColor = UIColor(globalTintColor)
            }
        }
    }
    @Published var secondaryTintColor: Color = .gray
    
    @Published var tertiaryTintColor: Color = .white
    
    @Published var isInternalSoundEnabled: Bool = true
    
    @Published var collisionSensitivity: CollisionSensitivity = .medium
    
    @Published var gravityX: CGFloat = 0.5 {
        didSet {
            setGravity(x: gravityX, y: gravityY)
        }
    }
    @Published var gravityY: CGFloat = 0.6 {
        didSet {
            setGravity(x: gravityX, y: gravityY)
        }
    }
    
    private var gravityYBeforeMotionEnabling = 0.0

    @Published var isMotionEnabled: Bool = false {
        didSet {
            if isMotionEnabled {
                gravityYBeforeMotionEnabling = gravityY
                // Handled by update method
            } else {
                gravityY = gravityYBeforeMotionEnabling
                gravityX = 0.5
            }
        }
    }
    @Published var noteLength: CGFloat = 0.5
    
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
        
    @Published var noteDots: [NoteDot] = []
    
    @Published var spawnPosition: CGPoint = .zero
    
    private var notesToFire: [(Int, Int, CGFloat)] = []
    private var noteFiringTimeWindow = 0.05
    private var previousTime: TimeInterval = .zero
    
    var keyPress: Int? {
        didSet {
            if let keyPress = keyPress {
                makeNoteDot(keyPress)
            }
        }
    }
    
    private var rotation: CGFloat = 0
    
    private var tombolaSegments: [SKShapeNode] = []
    
    private let motionManager = CMMotionManager()
    
    private let midiManager = ObservableMIDIManager(
        clientName: "FrenzyMIDIManager",
        model: "Frenzy",
        manufacturer: "Daniel Hooper"
    )
    
    private let midiHelper: MIDIHelper = MIDIHelper()

    override init() {
        super.init(size: .zero)

        scaleMode = .aspectFit
//        backgroundColor = .cyan
        
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 2.0
        setGravity(x: gravityX, y: gravityY)
        
        midiHelper.setup(midiManager: midiManager)
        
        midiHelper.didReceiveMIDIEvent = { [weak self] midiEvent in
            DispatchQueue.main.sync {
                switch midiEvent {
                case .noteOn(let noteOn):
                    self?.keyPress = Int(noteOn.note.number)
                case .cc(let cc):
                    self?.receiveMidiCC(cc)
                default:
                    break
                }
            }
        }
        
        // get the audio stuff setup by triggering it once here
        playPureTone(frequencyInHz: 0, amplitude: 0, durationInMillis: 0, completion: { })
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        spawnPosition = CGPoint(x: view.frame.midX, y: view.frame.midY)
        
        motionManager.startAccelerometerUpdates()

        view.backgroundColor = backgroundColor
        view.ignoresSiblingOrder = true

        physicsBody?.categoryBitMask = PhysicsCategory.worldBoundary.bitMask
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.bitMask
        physicsBody = SKPhysicsBody(edgeLoopFrom: view.frame.insetBy(dx: -16.0, dy: -16.0)) // dot radius minus 1

        makeTombolaSegments()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ currentTime: TimeInterval) {
        if previousTime == .zero {
            previousTime = currentTime
        }
        
        rotation += (rotationSpeed - 5) * 0.01 * -1
        tombolaSegments.forEach {
            $0.zRotation = rotation
        }

        // This allows us to concatenate note firing events that happen very close to eachother
        // which may produce unpleasent sounding results
        if previousTime + noteFiringTimeWindow < currentTime {
            fireMidiEvents()
            notesToFire = []
            previousTime = currentTime
        }
        
        if isMotionEnabled, let accelerometerData = motionManager.accelerometerData {
            /// Shift the range from `-1.0...1.0` to `0.0...2.0`, then cut it in half to `0.0...1.0`
            let adjustedX = (accelerometerData.acceleration.x + 1.0) * 0.5
            /// Same as above comment, but first reverse the accelerometer's y value by multiplying by -1
            let adjustedY = ((accelerometerData.acceleration.y * -1) + 1.0) * 0.5
    
            gravityX = adjustedX
            gravityY = adjustedY
        }

        super.update(currentTime)
    }
        
    private func fireMidiEvents() {
        notesToFire.forEach { [weak self] (note, velocity, noteLength) in
            self?.midiHelper.sendNoteOn(UInt7(note), velocity: velocity, noteOffDelay: noteLength)
            
            if self?.isInternalSoundEnabled ?? false {
                let freq = noteNumberToFrequency(note)
                let dur = cycleDurationInMilliseconds(forFrequency: freq)
                let v = normalize(value: Double(velocity), min: 0.0, max: 127.0, newMin: 0.0, newMax: 1.0) * 0.5
                playPureTone(frequencyInHz: freq, amplitude: Float(v), durationInMillis: dur * (500.0 * noteLength), completion: { })
            }
        }
    }
    
    private func receiveMidiCC(_ cc: MIDIEvent.CC) {
        let value = Double(cc.value.midi2Value)
        switch cc.controller.number {
        case 13: // Gravity
            guard isMotionEnabled == false else { return }
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 1.0)
            gravityY = normalizedValue
        case 14: // Note length
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.1, newMax: 1.0)
            noteLength = normalizedValue
        case 15: // Scale
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.1, newMax: 1.0)
            scale = normalizedValue
        case 16: // Torque
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 10.0)
            rotationSpeed = normalizedValue
        case 17: // Spread
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 180.0)
            segmentOffset = normalizedValue
        case 18: // Vertices
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 2.0, newMax: 13.0)
            numberOfSides = normalizedValue
        default:
            break
        }
    }
    
    private func setGravity(x: CGFloat = 0.0, y: CGFloat) {
        /// The gravity value range is `0.0...1.0`. By subtracting `-0.5`, we move the range to `-0.5...0.5` allowing the user to make either donwards or upwards gravity
        let adjustedX = x - 0.5
        let adjustedY = y - 0.5
        let gravityMultiplier = -2.0 // Create additional strength and reverse the values
        physicsWorld.gravity = CGVector(dx: adjustedX * gravityMultiplier,
                                        dy: adjustedY * gravityMultiplier)
    }
}

private extension GameScene {

    func makeNoteDot(_ noteValue: Int) {
        let noteDot = NoteDot(radius: 8.0, noteValue: noteValue, mass: 0.0)
        let viewFrame = view?.frame
        // We have to do some math here to convert from SwiftUI's upper-left coordinate space
        // To SpriteKit's bottom-left coordinate space
        let positionY = (viewFrame?.maxY ?? 0.0) - spawnPosition.y
        noteDot.position = CGPoint(x: spawnPosition.x, y: positionY)
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
        
        let points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
                
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
            segmentNode.lineWidth = 5.0
            segmentNode.lineCap = .round
            segmentNode.strokeColor = UIColor(globalTintColor)
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
        let collisionImpulse = min(500, contact.collisionImpulse)
        let velocity = Int(normalize(value: collisionImpulse, min: 0.0, max: 500.0, newMin: 0.0, newMax: 126.0))
        
        // This isn't correct, but it works.
        let dotBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
        
        // This is working, but doesn't make sense. dotBody isn't really the dot
        switch dotBody.categoryOfContact() {
        case .tombola:
            guard contact.collisionImpulse > collisionSensitivity.impactThreshold else { return }
            if let noteDotNode = contact.bodyB.node as? NoteDot {
                notesToFire.append((noteDotNode.noteValue, isVelocityFixed ? 127 : velocity, noteLength))
            }
        // This is supposed to be case .worldBoundary: but this contact stuff isn't figured out properly
        default:
            if let otherBody = contact.bodyB.node as? NoteDot {
                noteDots
                    .removeFirst(where: { $0.uuid == otherBody.uuid })?
                    .removeFromParent()
            }
        }
    }
}


import SwiftUI

#Preview {
    ContentView()
}
