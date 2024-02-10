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
//    
//    @EnvironmentObject var midiManager: ObservableMIDIManager
//    
//    @EnvironmentObject var midiHelper: MIDIHelper

    var noteCollection: Set<Int> = []
    
    var noteFiringTimeWindow = 0.1
    var previousTime: TimeInterval = .zero
    
    let bpm = 120.0
    
    var notes: Set<Int> = [] {
        didSet {
//            makeNoteDot(notes[0])
            makeNoteDot(notes.removeFirst())
        }
    }
    
    var r: CGFloat = 0
    
    var rotationSpeed = 2.5 {
        didSet {
//            tombola?.removeAllActions()
//            let rotate = SKAction.rotate(byAngle: rotationSpeed * 0.1, duration: 0.1)
//            let rotateRepeatedly = SKAction.repeatForever(rotate)
//            tombola?.run(rotateRepeatedly)
        }
    }
    
    var scale = 1.0 {
        didSet {
//            tombola?.xScale = scale
//            tombola?.yScale = scale
            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
                .enumerated()
                .forEach {
                    $0.element?.xScale = scale + (0.025 * Double($0.offset))
                    $0.element?.yScale = scale + (0.025 * Double($0.offset))
                }
        }
    }
    
    var numberOfSides: CGFloat = 6.0 {
        didSet {
            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
                .forEach {
                    $0?.removeFromParent()
                }
            
            makeTombola()
            
            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
                .forEach { 
                    $0?.xScale = scale
                    $0?.yScale = scale
                }
//            tombola?.xScale = scale
//            tombola?.yScale = scale
        }
    }
        
    private let motionManager = CMMotionManager()
    
    private var dot = Dot()
    private var tombola: SKShapeNode?
    private var tombola1: SKShapeNode?
    private var tombola2: SKShapeNode?
    private var tombola3: SKShapeNode?
    private var tombola4: SKShapeNode?
    private var tombola5: SKShapeNode?

    let playSound: (String) -> SKAction = {
        SKAction.playSoundFileNamed($0, waitForCompletion: false)
    }
    
    var midiManager = ObservableMIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    var midiHelper = MIDIHelper()

    override init() {
        super.init(size: .zero)
        
        midiHelper.setup(midiManager: midiManager)

        scaleMode = .aspectFit
        backgroundColor = .black
        
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 3.0
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -1)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = PhysicsCategory.worldBoundary.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

//        motionManager.startAccelerometerUpdates()

        view.backgroundColor = backgroundColor
        view.ignoresSiblingOrder = true
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(cameraNode)
        cameraNode.xScale = 2
        cameraNode.yScale = 2
        camera = cameraNode

        makeTombola()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        r += rotationSpeed * 0.01
//        tombola?.zRotation = r
        [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
            .forEach {
                $0?.zRotation = r
            }
        
        if previousTime == .zero {
            previousTime = currentTime
        }
        
        if previousTime + noteFiringTimeWindow < currentTime {
            fire()
            noteCollection = []
            previousTime = currentTime
        }
//        if let accelerometerData = motionManager.accelerometerData {
//            let z = 25.0 // 9.8
//            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * z, dy: accelerometerData.acceleration.y * z)
//        }
        super.update(currentTime)
    }
    
    func fire() {
        noteCollection
            .forEach { [weak self] in
                self?.midiHelper.sendNoteOn(UInt7($0))
            }
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        // Do something if user shakes screen
    }
}

private extension GameScene {

    func makeNoteDot(_ noteValue: Int) {
        let r = 5.0
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        let noteDot = SKShapeNode(path: path)
        noteDot.name = "\(noteValue)"
        noteDot.fillColor = .cyan
        noteDot.strokeColor = .cyan
        noteDot.physicsBody = SKPhysicsBody(circleOfRadius: r)
        noteDot.physicsBody?.mass = 1// r * 0.1
        noteDot.physicsBody?.restitution = 1
        noteDot.physicsBody?.friction = 0
        noteDot.physicsBody?.linearDamping = 0
        noteDot.physicsBody?.angularDamping = 0
        noteDot.physicsBody?.allowsRotation = true
        noteDot.physicsBody?.usesPreciseCollisionDetection = true
        noteDot.physicsBody?.categoryBitMask = PhysicsCategory.dot.rawValue
        noteDot.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue | PhysicsCategory.tombola.rawValue | PhysicsCategory.worldBoundary.rawValue
        noteDot.physicsBody?.contactTestBitMask = PhysicsCategory.tombola.rawValue | PhysicsCategory.worldBoundary.rawValue
        
        noteDot.position = CGPoint(x: view?.frame.midX ?? 0.0, y: view?.frame.midY ?? 0.0)
        
        addChild(noteDot)
    }
    
    func makeTombola() {
        
        let numberOfSides = Int(self.numberOfSides)
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
//        let halfW = tombolaSize * 0.5
//        let frame = CGRect(x: viewFrame.midX - halfW, y: viewFrame.midY + halfW, width: tombolaSize, height: tombolaSize)
//        let frame = viewFrame
        let path = CGMutablePath()
        var points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
        points.append(points[0]) // to close the drawing
        path.move(to: points[0])
        points.forEach { path.addLine(to: $0) }
        let tombola = SKShapeNode(points: &points, count: points.count)
        tombola.lineWidth = 2.0
        tombola.lineJoin = .round
        
        tombola.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
//        tombola.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        tombola.physicsBody?.affectedByGravity = false
//        tombola.physicsBody?.pinned = true
        tombola.physicsBody?.mass = 1000
        tombola.physicsBody?.allowsRotation = true
        tombola.physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
        tombola.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
        tombola.physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
        tombola.physicsBody?.usesPreciseCollisionDetection = true
        tombola.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
        self.tombola = tombola
        addChild(tombola)
        
        for i in (1...3) {
            let path = CGMutablePath()
            var points = calculatePolygonCoordinates(numberOfSides)
                .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
            points.append(points[0]) // to close the drawing
            path.move(to: points[0])
            points.forEach { path.addLine(to: $0) }
            let tombola = SKShapeNode(points: &points, count: points.count)
            tombola.lineWidth = 2.0
            tombola.lineJoin = .round
            tombola.strokeColor = .orange
            
            tombola.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
    //        tombola.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            tombola.physicsBody?.affectedByGravity = false
    //        tombola.physicsBody?.pinned = true
            tombola.physicsBody?.mass = 1000
            tombola.physicsBody?.allowsRotation = true
            tombola.physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
            tombola.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
            tombola.physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
//            tombola.physicsBody?.usesPreciseCollisionDetection = true
            tombola.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
//            self.tombola = tombola
            addChild(tombola)
//            tombolaBorders.append
            switch i {
            case 1:
                tombola1 = tombola
            case 2:
                tombola2 = tombola
            case 3:
                tombola3 = tombola
            case 4:
                tombola4 = tombola
            case 5:
                tombola5 = tombola
            default:
                break
            }
        }
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
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let dotBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
        
        switch dotBody.categoryOfContact() {
        case .tombola:
            let noteValueString = contact.bodyB.node?.name ?? ""
            let noteValue = Int(noteValueString) ?? -1
//            let midiValue = UInt7(min(127, noteValue))
            noteCollection.insert(noteValue)
        case .worldBoundary:
            print("Hit world boundary")
        default:
            print("⚠️")
            break
        }
    }
}

//extension CGPoint {
//    
//    func distance(from point: CGPoint) -> CGFloat {
//        CGFloat(
//            hypotf(Float(x - point.x), Float(y - point.y))
//        )
//    }
//}

enum PhysicsCategory: UInt32, CaseIterable {
    case dot, tombola, worldBoundary
}

extension SKPhysicsBody {
    
    func categoryOfContact() -> PhysicsCategory? {
        PhysicsCategory.allCases.first { categoryBitMask & $0.rawValue != 0 }
    }
}

import SwiftUI

#Preview {
    ContentView()
}
