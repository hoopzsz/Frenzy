//
//  Dot.swift
//  Line Square Dot
//
//  Created by Daniel Hooper on 2018-09-20.
//  Copyright © 2018 danielhooper. All rights reserved.
//

import SpriteKit.SKShapeNode

final class Dot: SKShapeNode {
        
    override init() {
        super.init()
        let r = 4.0
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        self.path = path
                        
        fillColor = .cyan
        strokeColor = .cyan
        
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
