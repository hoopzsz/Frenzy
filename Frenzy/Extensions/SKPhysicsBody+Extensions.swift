//
//  SKPhysicsBody+Extensions.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-06.
//

import SpriteKit

extension SKPhysicsBody {
    
    func categoryOfContact() -> PhysicsCategory? {
        PhysicsCategory.allCases.first { categoryBitMask & $0.bitMask != 0 }
    }
}
