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
    
    var rotationSpeed = 2.5
    
    var segmentOffset: CGFloat = 0.0 {
        didSet {
            tombolaSegments.forEach { $0.removeFromParent() }
            makeTombolaV2()
        }
    }

    var scale = 1.0 {
        didSet {
            tombolaSegments.forEach {
                $0.xScale = scale
                $0.yScale = scale
            }
//            tombola?.xScale = scale
//            tombola?.yScale = scale
//            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
//                .enumerated()
//                .forEach {
//                    $0.element?.xScale = scale + (0.025 * Double($0.offset))
//                    $0.element?.yScale = scale + (0.025 * Double($0.offset))
//                }
        }
    }
    
    var numberOfSides: CGFloat = 6.0 {
        didSet {
//            tombola?.removeFromParent()
            tombolaSegments.forEach {
                $0.removeFromParent()
            }
            makeTombola()
            tombolaSegments.forEach {
                $0.xScale = scale
                $0.yScale = scale
            }
//            tombola?.xScale = scale
//            tombola?.yScale = scale
//            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
//                .forEach {
//                    $0?.removeFromParent()
//                }

//            [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
//                .forEach { 
//                    $0?.xScale = scale
//                    $0?.yScale = scale
//                }
        }
    }
        
    private let motionManager = CMMotionManager()
    
    private var dot = Dot()
    private var tombola: SKShapeNode?
    private var tombolaSegments: [SKShapeNode] = []

//    private var tombola1: SKShapeNode?
//    private var tombola2: SKShapeNode?
//    private var tombola3: SKShapeNode?
//    private var tombola4: SKShapeNode?
//    private var tombola5: SKShapeNode?

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
        tombolaSegments.forEach {
            $0.zRotation = r
        }
//        tombola?.zRotation = r
//        [tombola, tombola1, tombola2, tombola3, tombola4, tombola5]
//            .forEach {
//                $0?.zRotation = r
//            }
        
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
        let r = 9.0
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
    
    func makeTombolaV2() {
        self.tombolaSegments = []
        let numberOfSides = Int(self.numberOfSides)
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
        
        let path = CGMutablePath()
        var points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
                
        let colors: [UIColor] = [.red, .blue, .green, .gray, .yellow, .purple, .systemPink ]
        var lookaheadIndex = 1
        for (index, point) in points.enumerated() {
            if lookaheadIndex == points.count {
                lookaheadIndex = 0
            }
            let path = CGMutablePath()
            let rotatedPoints = rotatePoints(point1: point, point2: points[lookaheadIndex],
                                             angle: degreesToRadians(degrees: segmentOffset))
//            path.move(to: point)
//            path.addLine(to: points[lookaheadIndex])
            path.move(to: rotatedPoints.0)
            path.addLine(to: rotatedPoints.1)
            let segmentNode = SKShapeNode(path: path)
            segmentNode.lineWidth = 3.0
            segmentNode.strokeColor = .white // colors.randomElement() ?? .white
            segmentNode.physicsBody = SKPhysicsBody(edgeChainFrom: path)
    //        tombola.physicsBody = SKPhysicsBody(edgeChainFrom: path)
            segmentNode.physicsBody?.affectedByGravity = false
            segmentNode.physicsBody?.pinned = true
            segmentNode.physicsBody?.mass = 1000
            segmentNode.physicsBody?.allowsRotation = true
            segmentNode.physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
            segmentNode.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
            segmentNode.physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
            segmentNode.physicsBody?.usesPreciseCollisionDetection = true
            segmentNode.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
            self.tombolaSegments.append(segmentNode)
            addChild(segmentNode)
            lookaheadIndex += 1
        }
    }
    
    func makeTombola() {
        makeTombolaV2()
        return
        
        let numberOfSides = Int(self.numberOfSides)
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
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
        
//        for i in (1...3) {
//            let path = CGMutablePath()
//            var points = calculatePolygonCoordinates(numberOfSides)
//                .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
//            points.append(points[0]) // to close the drawing
//            path.move(to: points[0])
//            points.forEach { path.addLine(to: $0) }
//            let tombola = SKShapeNode(points: &points, count: points.count)
//            tombola.lineWidth = 2.0
//            tombola.lineJoin = .round
//            tombola.strokeColor = .orange
//            
//            tombola.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
//    //        tombola.physicsBody = SKPhysicsBody(edgeChainFrom: path)
//            tombola.physicsBody?.affectedByGravity = false
//    //        tombola.physicsBody?.pinned = true
//            tombola.physicsBody?.mass = 1000
//            tombola.physicsBody?.allowsRotation = true
//            tombola.physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
//            tombola.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
//            tombola.physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
////            tombola.physicsBody?.usesPreciseCollisionDetection = true
//            tombola.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
////            self.tombola = tombola
//            addChild(tombola)
////            tombolaBorders.append
//            switch i {
//            case 1:
//                tombola1 = tombola
//            case 2:
//                tombola2 = tombola
//            case 3:
//                tombola3 = tombola
//            case 4:
//                tombola4 = tombola
//            case 5:
//                tombola5 = tombola
//            default:
//                break
//            }
//        }
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
//func rotate(point: CGPoint, by angle: CGFloat) -> CGPoint {
//    let x = point.x
//    let y = point.y
//    let rotatedX = x * cos(angle) - y * sin(angle)
//    let rotatedY = x * sin(angle) + y * sin(angle)
//    return CGPoint(x: rotatedX, y: rotatedY)
//}
//
//func rotatePoints(point1: CGPoint, point2: CGPoint, angle: CGFloat) -> (CGPoint, CGPoint) {
//    let centerX = point1.x + point2.x / 2.0
//    let centerY = point1.y + point2.y / 2.0
//    let center = CGPoint(x: centerX, y: centerY)
//    
//    let translatedPoint1 = CGPoint(x: point1.x - center.x, y: point1.y - center.y)
//    let translatedPoint2 = CGPoint(x: point2.x - center.x, y: point2.y - center.y)
//    
//    let rotatedPoint1 = rotate(point: translatedPoint1, by: angle)
//    let rotatedPoint2 = rotate(point: translatedPoint2, by: angle)
//    
//    let finalPoint1 = CGPoint(x: rotatedPoint1.x + center.x, y: rotatedPoint1.y + center.y)
//    let finalPoint2 = CGPoint(x: rotatedPoint2.x + center.x, y: rotatedPoint2.y + center.y)
//    
//    return (finalPoint1, finalPoint2)
//}
//def rotate_points(point1, point2, angle):
//    """Rotate two points around their center by a given angle (in radians)."""
//    # Calculate the center point
//    center = ((point1[0] + point2[0]) / 2, (point1[1] + point2[1]) / 2)
//    
//    # Translate points to origin
//    translated_point1 = (point1[0] - center[0], point1[1] - center[1])
//    translated_point2 = (point2[0] - center[0], point2[1] - center[1])
//    
//    # Rotate translated points
//    rotated_point1 = rotate_point(translated_point1, angle)
//    rotated_point2 = rotate_point(translated_point2, angle)
//    
//    # Translate rotated points back
//    rotated_point1 = (rotated_point1[0] + center[0], rotated_point1[1] + center[1])
//    rotated_point2 = (rotated_point2[0] + center[0], rotated_point2[1] + center[1])
//    
//    return rotated_point1, rotated_point2
