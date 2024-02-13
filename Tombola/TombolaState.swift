//
//  TombolaState.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import Foundation

final class TombolaState: ObservableObject {
    
    /// The note values in the scene
    /// For example, a value of 35 represents C3, while 37 would then be D3
    @Published var notes: [Int] = []
    
    /// The gravity of the scene which affects the notes.
    ///
    /// Values should be from 0.0 to 1.0, where `0.0..<0.5` represents negative, or reverse gravity,
    /// and `0.5...1.0` represents positive, or normal downwards gravity
    @Published var gravity: CGFloat = 0.75

    /// The mass for note values.
    /// Values should be from 0.0 to 1.0.
    @Published var mass: CGFloat = 0.0
    
    /// The scale of the polygon.
    /// Values should be from 0.0 to 1.0.
    @Published var scale: CGFloat = 0.5
    
    /// The amount of rotation applied to the entire polygon.
    /// Values should be from 0.0 to 1.0, where `0.0..<0.5` creates leftward rotation,
    /// `0.5` stops rotation, and `0.51...1.0` creates rightward rotation
    @Published var torque: CGFloat = 0.5
    
    /// The rotation factor of each individual side of the polygon, allowing the polygon to "spread" open.
    /// Values should be from 0.0 to 180.0, which represent degrees.
    @Published var spread: CGFloat = 0.0
    
    /// The number of vertices in the scene's polygon.
    /// This can also be thought of as the number of sides.
    /// For example, a value of 3 would make a triangle, while a value of 4 would make a square.
    @Published var vertices: Int = 6
    
    /// Where notes should be positioned when they're added to a scene.
    /// This position should be treated as an offset from the center of the scene
    /// but while still using SpriteKit's bottom-left origin coordinate system.
    /// For example, a value of (-100, -100) should place the spawn position towards the bottom left of the scene.
    @Published var spawnPosition: CGPoint = .zero
}
