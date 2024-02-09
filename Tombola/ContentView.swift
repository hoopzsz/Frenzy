//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import SwiftUI
import SpriteKit

struct ContentView: View {

    @StateObject var gameScene = GameScene(size: UIScreen.main.bounds.size)

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
                .padding()
        }
//        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
