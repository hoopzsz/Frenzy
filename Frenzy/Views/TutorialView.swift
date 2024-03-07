//
//  TutorialView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-03.
//

import SpriteKit
import SwiftUI

struct TutorialView: View {
        
    var body: some View {
        VStack {
            HStack {
                TutorialHeaderView()
                    .foregroundColor(.white)
                Spacer()
            }
            VStack {
                Text("""
                
                Frenzy is a MIDI sequencer that uses objects in a physics environment to generate random patterns of notes.
                
                A tone generator is included to help you begin. It can be disabled after you have set up MIDI connections for other apps or devices.
                
                """)
                .foregroundColor(.white)

                Link("Learn more about MIDI here.",
                     destination: URL(string: "https://en.wikipedia.org/wiki/MIDI")!)
                .tint(Color.orange)
                .padding()
            }
            .italic()
            .multilineTextAlignment(.leading)

            Spacer()
            
            Button(action: {
                // Action to perform when the button is tapped
            }) {
                Text("Get Started")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12.0)
                            .fill(Color.orange)
                    )
            }
        }
        .padding()
        .background(
            Color.black.ignoresSafeArea()
        )
    }
}

struct TutorialHeaderView: View {
    
    let gameScene = GameScene()

    var body: some View {
        HStack {
            SpriteView(scene: gameScene)
                .frame(width: 80, height: 80)
            VStack(alignment: .leading) {
            Text("Frenzy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .italic()
            Text("Physics-driven MIDI Sequencer")
                .font(.subheadline)
                .italic()
            }
        }
        .onAppear {
            gameScene.size = CGSize(width: 80, height: 80)
            gameScene.rotationSpeed = 7.5
            gameScene.scale = 0.9
            gameScene.spawnPosition = CGPoint(x: 20, y: 40)
            gameScene.backgroundColor = .black
        }
    }
}

#Preview {
    TutorialView()
}
