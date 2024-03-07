//
//  ContentView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    
    @State var spawnViewSize: CGFloat = 1.0
    @State var presentingSettings: Bool = false
    @State var presentingTutorial: Bool = false
    @State var isKeyboardVisible = true
    @State var keyboardOffset: CGFloat = 0.0
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    FrenzyView(spawnViewSize: $spawnViewSize, gameScene: gameScene)
                    Spacer()
                    VStack {
                        Spacer()
                        ControlsView(gravityY: $gameScene.gravityY,
                                     noteLength: $gameScene.noteLength,
                                     scale: $gameScene.scale,
                                     rotationSpeed: $gameScene.rotationSpeed,
                                     segmentOffset: $gameScene.segmentOffset,
                                     numberOfSides: $gameScene.numberOfSides,
                                     isKeyboardVisible: $isKeyboardVisible,
                                     isMotionEnabled: $gameScene.isMotionEnabled,
                                     tintColor: gameScene.secondaryTintColor)
                        .padding(8.0)
                        if isKeyboardVisible {
                            SlidingKeyboardView(keyboardOffset: $keyboardOffset,
                                                keyPress: $gameScene.keyPress,
                                                globalTintColor: $gameScene.globalTintColor,
                                                secondaryTintColor: $gameScene.secondaryTintColor,
                                                idealHeight: geometry.size.height * 0.2)
                            .padding(8.0)
                        }
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
        .tint(gameScene.globalTintColor)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Button("Accelerometer",
                           systemImage: gameScene.isMotionEnabled ? "m.square.fill" : "m.square") {
                        gameScene.isMotionEnabled.toggle()
                    }
                    Button("Audio",
                           systemImage: gameScene.isInternalSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle") {
                        gameScene.isInternalSoundEnabled.toggle()
                    }
                    Button("Settings",
                           systemImage: "gearshape.fill") {
                        presentingSettings.toggle()
                    }
                   .sheet(isPresented: $presentingSettings) {
                       SettingsView(midiChannelOutput: $gameScene.midiChannelOutput,
                                    midiChannelInput: $gameScene.midiChannelInput,
                                    isVelocityFixed: $gameScene.isVelocityFixed,
                                    globalTintColor: $gameScene.globalTintColor,
                                    secondaryTintColor: $gameScene.secondaryTintColor,
                                    isKeyboardVisible: $isKeyboardVisible,
                                    collisionSensitiviy: $gameScene.collisionSensitivity)
                   }
                }
            }
        }
        .sheet(isPresented: $presentingTutorial) {
            TutorialView()
        }
        .onAppear {
            gameScene.backgroundColor = .black
            
            let sliderSymbolConfig = UIImage.SymbolConfiguration(scale: .medium)
            let sliderThumbImage = UIImage(systemName: "circle.fill", withConfiguration: sliderSymbolConfig)?
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(.white)
            
            UISlider
                .appearance()
                .setThumbImage(sliderThumbImage, for: .normal)
            
//            UserDefaults.standard.setValue(false, forKey: "hasSeenTutorial")

            let hasSeenTutorial = UserDefaults.standard.bool(forKey: "hasSeenTutorial")
            
            if !hasSeenTutorial {
                UserDefaults.standard.setValue(true, forKey: "hasSeenTutorial")
                presentingTutorial = true
            }
        }
    }
}

#Preview {
    ContentView()
}
