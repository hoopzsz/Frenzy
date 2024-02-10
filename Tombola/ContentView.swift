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
        DynamicStack {
            GeometryReader { geometry in
                self.updateSize(geometry.size)
                SpriteView(scene: gameScene,
                           debugOptions: [
//                            .showsFPS,
//                                          .showsDrawCount,
//                                          .showsNodeCount,
                                          .showsPhysics,
//                                          .showsQuadCount])
                                          ])
            }
            VStack {
                Slider(value: $gameScene.scale,
                       in: 0.0...2.0,
                       step: 0.01,
                       onEditingChanged: { onEditingChanged in
                    //                    print(onEditingChanged)
                })
                Slider(value: $gameScene.rotationSpeed,
                       in: 0.0...4.0,
                       step: 0.01,
                       onEditingChanged: { onEditingChanged in
                    //                    print(onEditingChanged)
                })
                Slider(value: $gameScene.numberOfSides,
                       in: 4.0...13.0,
                       step: 1,
                       onEditingChanged: { onEditingChanged in
                    //                    print(onEditingChanged)
                })
                
                Slider(value: $gameScene.segmentOffset,
                       in: 0.0...180.0,
                       step: 1.0,
                       onEditingChanged: { onEditingChanged in
                    //                    print(onEditingChanged)
                })
                PianoView(startingKey: 36, numberOfKeys: 12, selectedKeys: $gameScene.notes)
                    .padding(4.0)
                    .aspectRatio(2.5, contentMode: .fit)
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private func updateSize(_ size: CGSize) -> AnyView? {
        gameScene.size = size
        return nil
    }
}

#Preview {
    ContentView()
}

struct DynamicStack<Content: View>: View {
    
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var horizontalAlignment = HorizontalAlignment.center
    var verticalAlignment = VerticalAlignment.center
    var spacing: CGFloat?

    var body: some View {
        switch sizeClass {
        case .regular:
            hStack
        case .compact, .none:
            vStack
        @unknown default:
            vStack
        }
    }
}

private extension DynamicStack {
    var hStack: some View {
        HStack(
            alignment: verticalAlignment,
            spacing: spacing,
            content: content
        )
    }

    var vStack: some View {
        VStack(
            alignment: horizontalAlignment,
            spacing: spacing,
            content: content
        )
    }
}
