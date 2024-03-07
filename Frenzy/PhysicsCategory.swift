//
//  PhysicsCategory.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-06.
//

import Foundation

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
