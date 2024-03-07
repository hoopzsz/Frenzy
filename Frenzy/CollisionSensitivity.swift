//
//  CollisionSensitivity.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-03-06.
//

import Foundation

enum CollisionSensitivity: Int {
    
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .low:
            "low"
        case .medium:
            "medium"
        case .high:
            "high"
        }
    }
    
    var impactThreshold: CGFloat {
        switch self {
        case .low:
            30
        case .medium:
            15
        case .high:
            2
        }
    }
}
