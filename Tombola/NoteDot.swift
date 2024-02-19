//
//  NoteDot.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SpriteKit.SKShapeNode

final class NoteDot: SKShapeNode {
    
    let noteValue: Int
    let uuid = UUID()
    
    init(radius: CGFloat, noteValue: Int, mass: CGFloat, color: UIColor = .white) {
        self.noteValue = noteValue
        
        super.init()
    
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        self.path = path

        fillColor = color
        strokeColor = color
        physicsBody = SKPhysicsBody(circleOfRadius: radius)
        physicsBody?.mass = mass
        physicsBody?.density = mass
        physicsBody?.friction = 0
        physicsBody?.restitution = 1
        physicsBody?.linearDamping = 0
        physicsBody?.angularDamping = 0
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
