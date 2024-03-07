//
//  FrenzyView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-06.
//

import SpriteKit
import SwiftUI

struct FrenzyView: View {
    
    @Binding var spawnViewSize: CGFloat
    @ObservedObject var gameScene: GameScene
    
    var body: some View {
        GeometryReader { geometry in
            self.updateSize(geometry.size)
            ZStack {
                SpriteView(scene: gameScene)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("GameScene"))
                            .onEnded { _ in
                                spawnViewSize = 1.0
                            }
                            .onChanged { drag in
                                spawnViewSize = 2
                                gameScene.spawnPosition = drag.location
                            }
                    )
            
                VStack {
                    Spacer()
                    HStack {
                        GravityView(gravityX: $gameScene.gravityX,
                                    gravityY: $gameScene.gravityY,
                                    strokeColor: $gameScene.secondaryTintColor,
                                    indicatorColor: $gameScene.globalTintColor)
                        Spacer()
                    }
                }
                .padding(8.0)
                
                NoteIndicatorView(startingNote: 0,
                                  numberOfNotes: 127,
                                  notes: notesFromNodes($gameScene.noteDots.wrappedValue))
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                SpawnPositionView()
                    .scaleEffect(spawnViewSize)
                    .animation(.easeInOut, value: 0.2)
                    .position(gameScene.spawnPosition)
                    .foregroundColor(gameScene.secondaryTintColor)
                
            }
            .aspectRatio(1.0, contentMode: .fit)
            .coordinateSpace(name: "GameScene")
        }
    }
    
    private func notesFromNodes(_ nodes: [NoteDot]) -> [Int] {
        nodes.map { $0.noteValue }
    }
    
    private func updateSize(_ size: CGSize) -> AnyView? {
        gameScene.size = size
        return nil
    }
}
