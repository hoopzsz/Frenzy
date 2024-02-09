//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.updateSize(geometry.size)
                SpriteView(scene: gameScene,
                           debugOptions: [.showsFPS,
                                          .showsDrawCount,
                                          .showsNodeCount,
                                          .showsQuadCount])
                .ignoresSafeArea()
            }
            Spacer()
            Slider(value: $gameScene.scale,
                   in: 0.0...1.0,
                   step: 0.01,
                   onEditingChanged: { onEditingChanged in
//                    print(onEditingChanged)
            })
            .padding()
            Slider(value: $gameScene.rotationSpeed,
                   in: 0.0...5.0,
                   step: 0.1,
                   onEditingChanged: { onEditingChanged in
//                    print(onEditingChanged)
            })
            .padding()
            Spacer()
            Text("Keyboard goes here")
                .foregroundStyle(Color.white)
                .padding()
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
    
    private func updateSize(_ size: CGSize) -> AnyView? {
        gameScene.size = size
        return nil
    }
}

struct GameSceneView: View {

    @StateObject var gameScene: GameScene

    var body: some View {
        VStack {
            GeometryReader { geometry in
//                SpriteView(scene: GameScene(size: geometry.size),
                SpriteView(scene: gameScene,
                           debugOptions: [.showsFPS,
                                          .showsDrawCount,
                                          .showsNodeCount,
                                          .showsQuadCount])
                .ignoresSafeArea()
            }
            .border(Color.red, width: 2.0)
        }
    }
}

#Preview {
    ContentView()
}
