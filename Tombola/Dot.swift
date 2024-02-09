//
//  Dot.swift
//  Line Square Dot
//
//  Created by Daniel Hooper on 2018-09-20.
//  Copyright © 2018 danielhooper. All rights reserved.
//

import SpriteKit.SKShapeNode

final class Dot: SKShapeNode {
    
    private let categoryBitMask = PhysicsCategory.dot.rawValue
    
    override init() {
        super.init()
        let r = 8.0
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        self.path = path
                        
//        alpha = 1
//        zPosition = 1
        fillColor = .blue
        strokeColor = .blue
        
        physicsBody = SKPhysicsBody(circleOfRadius: r)
        physicsBody?.mass = 0// r * 0.1
        physicsBody?.restitution = 1.0
        physicsBody?.friction = 0
        physicsBody?.linearDamping = 0
        physicsBody?.angularDamping = 0
        physicsBody?.allowsRotation = true
        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.categoryBitMask = PhysicsCategory.dot.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.tombola.rawValue | PhysicsCategory.worldBoundary.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.tombola.rawValue | PhysicsCategory.worldBoundary.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    private func disableCollision() {
//        physicsBody?.categoryBitMask = 0
//        physicsBody?.contactTestBitMask = 0
//        physicsBody?.collisionBitMask = PhysicsCategory.worldBoundary.rawValue
//    }
}

final class Tombola: SKShapeNode {
    
    convenience init(length: CGFloat) {
        let size = CGSize(width: length, height: length)
        self.init(rectOf: size)

        lineWidth = 2
        fillColor = .clear
//        strokeColor = .white
        
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.mass = 100
        physicsBody?.allowsRotation = false
        physicsBody?.affectedByGravity = false
        
        physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
        
//        zPosition = 1
    }
    
    /// Disables collision and performs a smooth animation to the next position. Collision is renabled after the animation completes.
//    func move(to position: CGPoint) {
//        physicsBody?.collisionBitMask = 0
//        physicsBody?.contactTestBitMask = 0
//        let action = SKAction.move(to: position, duration: 1)
//        action.timingMode = .easeInEaseOut
//        run(action) {
//            self.physicsBody?.collisionBitMask = Category.dot.bitMask
//            self.physicsBody?.contactTestBitMask = Category.dot.bitMask
//        }
//    }
//    
//    func animateFill() {
//        run(SKAction.repeat(SKAction.sequence([customActionForColor(.white), customActionForColor(.clear)]), count: 3))
//    }
//    
//    private func customActionForColor(_ color: UIColor) -> SKAction {
//        SKAction.customAction(withDuration: 0.1) { _, _ in
//            self.fillColor = color
//        }
//    }
}


final class Line: SKShapeNode {
    
    init(path: CGPath) {
        super.init()
        
        self.path = path
        
        lineCap = .round
        lineWidth = 2.0
        lineJoin = .miter
        strokeColor = .white
        
        physicsBody?.friction = 0.0
        physicsBody?.restitution = 1.0
        physicsBody?.affectedByGravity = false
//        physicsBody?.usesPreciseCollisionDetection = true
        physicsBody?.categoryBitMask = PhysicsCategory.tombola.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.dot.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.rawValue
//        physicsBody?.usesPreciseCollisionDetection = true
    }
    
//    convenience init(initialPosition position: CGPoint) {
//        let path = CGMutablePath()
//        path.move(to: position)
//        path.addLine(to: position)
//        
//        self.init(path: path)
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    func addPhysicsBody(_ body: SKPhysicsBody) {
//        body.affectedByGravity = false
//        body.categoryBitMask = PhysicsCategory.tombola.rawValue
//        body.collisionBitMask = PhysicsCategory.dot.rawValue
//        body.contactTestBitMask = PhysicsCategory.dot.rawValue
//        physicsBody = body
//    }
}
