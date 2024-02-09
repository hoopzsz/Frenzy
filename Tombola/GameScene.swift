//
//  GameScene.swift
//  Line Square Dot
//
//  Created by Daniel Hooper on 2018-09-20.
//  Copyright © 2018 danielhooper. All rights reserved.
//

import SpriteKit
import CoreMotion

final class GameScene: SKScene, ObservableObject {

    var r: CGFloat = 0
    
    var rotationSpeed = 1.0 {
        didSet {
            r
//            tombola?.removeAllActions()
//            tombola?.removeAllActions()
//            let rotate = SKAction.rotate(byAngle: 1.0, duration: rotationSpeed)
//            let repeatedRotate = SKAction.repeatForever(rotate)
//            tombola?.run(repeatedRotate)
//            tombola?.zRotation = rotationSpeed * 0.1
        }
    }
    
    var scale = 1.0 {
        didSet {
            print("didSet scale : \(scale)")
//            tombola?.xScale = scale
//            tombola?.yScale = scale
            
            let scaleAction = SKAction.scale(to: scale, duration: 0.0)
//            let scaleDownAction = SKAction.scale(to: 1.0, duration: 1.0)
//            print("tombola: \(self.tombola)")
            tombola?.xScale = scale
            tombola?.yScale = scale
            tombola?.run(scaleAction)
        }
    }
    
    var selectedNode: SKShapeNode? = nil
    
    private let motionManager = CMMotionManager()
    
    private var dot = Dot()
    private var tombola: SKShapeNode?
    
    let playSound: (String) -> SKAction = {
        SKAction.playSoundFileNamed($0, waitForCompletion: false)
    }

    override init(size: CGSize) {
        super.init(size: size)

//        run(playSound(""))
        scaleMode = .aspectFit
        backgroundColor = .darkGray
        
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 1.0
//        physicsWorld.gravity = CGVector(dx: 0.0, dy: -0.1)
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.categoryBitMask = PhysicsCategory.worldBoundary.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue

    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

//        motionManager.startAccelerometerUpdates()

        view.isMultipleTouchEnabled = false
        view.backgroundColor = backgroundColor
        view.showsFPS = true
        view.showsNodeCount = true
        view.showsPhysics = true
        
        spawnDot()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func pan(sender: UIPanGestureRecognizer) {
//        print(sender.)
    }
    
    @objc private func pinch(sender: UIPinchGestureRecognizer) {
//        guard let view = view else { return }
        
//        selectNode(at: sender.location(in: view))
//        guard let selectedNode = selectedNode else { return }
//        let currentNodeScale = CGSize(width: selectedNode.xScale, height: selectedNode.yScale)
//        selectedNode.run(.scale(by: sender.scale, duration: 0.000))
//        sender.scale = 1
//        selectedNode?.setScale(sender.scale)
        
    }
}

extension GameScene {

    override func update(_ currentTime: TimeInterval) {
        r += 1 * rotationSpeed * 0.01
        tombola?.zRotation = r
//        if dot.isIdle {
//            newGame()
//        }
//        if let accelerometerData = motionManager.accelerometerData {
//            let z = 25.0 // 9.8
//            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * z, dy: accelerometerData.acceleration.y * z)
//        }
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
//        if event == z {
//            scene?.removeAllChildren()
//        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//
//        guard let position = locationOf(touches, in: self) else { return }
//
//        ignoreTouchesMoved = false
//        touchDown = position
//
//
//        line = Line(initialPosition: position)
//
//        guard let line = line else { return }
//
//        addChild(line)
//    }
//
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
//
//        guard !ignoreTouchesMoved, let position = locationOf(touches, in: self) else { return }
//
//        touchUp = position
//
//        let path = CGMutablePath()
//        path.move(to: touchDown)
//        path.addLine(to: position)
//
//        line?.path = path
//
//        let maxDistance: CGFloat = 256.0
//        if touchDown.distance(from: position) > maxDistance {
//            ignoreTouchesMoved = true
//            addLine()
//        }
//
//    }
//
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
//        selectedNode?.physicsBody?.affectedByGravity = true
//        selectedNode = nil
//
//        guard let position = locationOf(touches, in: self), !ignoreTouchesMoved else { return }
//
//        guard position.distance(from: touchDown) > 48 else {
//            line?.removeFromParent()
//            return
//        }
//
//        addLine()
    }
}

private extension GameScene {

    func spawnDot() {
        removeAllChildren()
        dot = Dot()
        dot.position = CGPoint(x: view?.frame.midX ?? 0.0, y: view?.frame.midY ?? 0.0)
        addChild(dot)
        
        makeTombola()
//        dot.run(SKAction.fadeIn(withDuration: 1))
    }
    
    func makeTombola() {
        let numberOfSides = 3
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
        let halfW = tombolaSize * 0.5
        let frame = CGRect(x: viewFrame.midX - halfW, y: viewFrame.midY - halfW, width: tombolaSize, height: tombolaSize)
        let path = CGMutablePath()
        var points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
        points.append(points[0]) // to close the drawing
        path.move(to: points[0])
        points.forEach { path.addLine(to: $0) }
        let tombola = SKShapeNode(points: &points, count: points.count)
        tombola.lineWidth = 2.0
        tombola.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        tombola.physicsBody?.affectedByGravity = false
        tombola.physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
        tombola.physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
        tombola.physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
        tombola.physicsBody?.usesPreciseCollisionDetection = true
        tombola.position = CGPoint(x: frame.origin.x + halfW, y: frame.origin.y + halfW)
        self.tombola = tombola
//        let rotate = SKAction.rotate(byAngle: 1, duration: 1.0)
//        let repeatedRotate = SKAction.repeatForever(rotate)
//        tombola.run(repeatedRotate)
        addChild(tombola)
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

//
//    func addLine() {
//        line?.addPhysicsBody(SKPhysicsBody(edgeFrom: touchDown, to: touchUp))
//        line?.run(SKAction.fadeIn(withDuration: 0.2))
//        line?.physicsBody?.affectedByGravity = true
//    }
//
//    func moveSquare() {
//        let padding = 16
//        let topPadding = Int(frame.height * 0.5)
//        let x = Int.random(in: padding..<(Int(frame.width) - padding))
//        let y = Int.random(in: padding..<topPadding)
//        let randomPosition = CGPoint(x: x, y: y)
//        square.move(to: randomPosition)
//    }

    func locationOf(_ touches: Set<UITouch>, in node: SKNode) -> CGPoint? {
        touches.first?.location(in: node)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let dotBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
        switch dotBody.categoryOfContact() {
        case .tombola:
//            print("Hit tombola")
            break
        case .worldBoundary:
            print("Hit world boundary")
        default:
            break
        }
    }
}

extension GameScene {
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//
//        return
//        print("⚠️ touches.count: \(touches.count)")
////        print("⚠️ touchesBegan: \(touches)\nwith event: \(event)")
//
//        guard let position = locationOf(touches, in: self) else { return }
//
//        selectNode(at: position)
//    }

//    private func selectNode(at touchLocation: CGPoint) {
//        guard let touchedNode = nodes(at: touchLocation).first, touchedNode is SKShapeNode else { return }
//        
//        touchedNode.physicsBody?.affectedByGravity = false
//        touchedNode.physicsBody?.velocity = .zero
//        touchedNode.removeAllActions()
//
//        selectedNode = touchedNode as? SKShapeNode
//    }

//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesMoved(touches, with: event)
//return
//        print("⚠️ touches.count: \(touches.count)")
////        print("⚠️ touchesMoved: \(touches)\nwith event: \(event)")
//
//        guard let touch = touches.first else { return }
////        guard let position = locationOf(touches, in: self) else { return }
//
//        let positionInScene = touch.location(in: view)
//        let previousPosition = touch.previousLocation(in: view)
//        let translation = CGPoint(x: positionInScene.x - previousPosition.x, y: positionInScene.y - previousPosition.y)
//
//        panForTranslation(translation: translation)
//    }
    
//    func panForTranslation(translation: CGPoint) {
//        guard let position = selectedNode?.position else { return }
//      
//        selectedNode?.position = CGPoint(x: position.x + translation.x, y: position.y - translation.y)
//    }
    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        return
//        print("⚠️ touchesEnded: \(touches)\nwith event: \(event)")
//
//        selectedNode?.physicsBody?.affectedByGravity = true
//        super.touchesEnded(touches, with: event)
//
//        guard let position = locationOf(touches, in: self), !ignoreTouchesMoved else { return }
//
//        guard position.distance(from: touchDown) > 48 else {
//            line?.removeFromParent()
//            return
//        }
//
//        addLine()
//    }
}

extension CGPoint {
    
    func distance(from point: CGPoint) -> CGFloat {
        CGFloat(
            hypotf(Float(x - point.x), Float(y - point.y))
        )
    }
}

enum PhysicsCategory: UInt32, CaseIterable {
    case dot, tombola, worldBoundary
}

//enum Category: CaseIterable {
//
//    case line, square, dot, boundary
//
//    var bitMask: UInt32 {
//        switch self {
//        case .dot: return 0x1 << 0
//        case .line: return 0x1 << 1
//        case .square: return 0x1 << 3
//        case .boundary: return 0x1 << 2
//        }
//    }
//}

//import SpriteKit.SKPhysicsBody

extension SKPhysicsBody {
    
    func categoryOfContact() -> PhysicsCategory? {
        PhysicsCategory.allCases.first { categoryBitMask & $0.rawValue != 0 }
    }
}


extension SKShapeNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
}

import SwiftUI

#Preview {
    ContentView()
}

