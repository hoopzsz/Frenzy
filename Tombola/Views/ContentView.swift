//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI
import SpriteKit

private let gravitySliderRange: ClosedRange<CGFloat> = 0.0...1.0
private let noteLengthRange: ClosedRange<CGFloat> = 0.1...1.0
private let scaleSliderRange: ClosedRange<CGFloat> = 0.1...1.0
private let torqueSliderRange: ClosedRange<CGFloat> = 0.0...10.0
private let spreadSliderRange: ClosedRange<CGFloat> = 0.0...180.0
private let verticesSliderRange: ClosedRange<CGFloat> = 2.0...13.0

private let smallSliderStep = 0.01
private let normalSliderStep = 1.0

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    @State var spawnViewSize: CGFloat = 1.0
    @State var presentingSettings: Bool = false
    @State var isKeyboardVisible = true
    @State var keyboardOffset: CGFloat = 0.0
    
    var body: some View {
        NavigationStack {
            DynamicStack {
                GeometryReader { geometry in
                    self.updateSize(geometry.size)
                    ZStack {
                        SpriteView(scene: gameScene,
                                   debugOptions: [])
//                                   debugOptions: [.showsFPS, .showsNodeCount, .showsFields, .showsPhysics])
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
//                    .aspectRatio(1.0, contentMode: .fit)
                    .coordinateSpace(name: "GameScene")
                }
                
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
//                    .padding(8.0)
                    if isKeyboardVisible {
                        SlidableKeyboardView(keyboardOffset: $keyboardOffset, keyPress: $gameScene.keyPress, globalTintColor: $gameScene.globalTintColor, secondaryTintColor: $gameScene.secondaryTintColor)
//                            .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 0.0))
                    }
                }
                .padding(8.0)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button("Accelerometer",
                               systemImage: gameScene.isMotionEnabled ? "m.square.fill" : "m.square") {
                            gameScene.isMotionEnabled.toggle()
                        }
//                        Button("Audio",
//                               systemImage: gameScene.isInternalSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle") {
//                            gameScene.isInternalSoundEnabled.toggle()
//                        }
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
            .tint(gameScene.globalTintColor)
        }
        .onShake {
//            gameScene.didShake.toggle()
        }
        .onAppear {
            let progressCircleConfig = UIImage.SymbolConfiguration(scale: .medium)
            let image = UIImage(
                systemName: "circle.fill",
                withConfiguration: progressCircleConfig
            )?.withRenderingMode(.alwaysTemplate).withTintColor(.white)
            
            UISlider
                .appearance()
                .setThumbImage(image, for: .normal)
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

#Preview {
    ContentView()
}

struct SlidableKeyboardView: View {
    
    @Binding var keyboardOffset: CGFloat
    @Binding var keyPress: Int?
    @Binding var globalTintColor: Color
    @Binding var secondaryTintColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            LazyVStack {
//                                                Spacer()
//                ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack {
                    PianoView(keyPress: $keyPress,
                              startingKey: 0,
                              numberOfKeys: 108,
                              whiteKeyColor: $globalTintColor,
                              blackKeyColor: $secondaryTintColor)
                    .frame(width: geometry.size.width * 9.0, height: 150)
                    .offset(x: self.keyboardOffset * -1.0)
                    //                                    .aspectRatio(, contentMode: .fit)
                }
                let min = geometry.size.width * -4.0
                Slider(value: $keyboardOffset, in: min...(max(1.0, geometry.size.width * 4.0)), step: 1.0)
//                Slider(value: $keyboardOffset, in: 0.0...(max(1.0, geometry.size.width * 8.0)), step: 1.0)
//                    .frame(width: geometry.size.width)
            }
        }
    }
}

struct ControlsView: View {
    
    @Binding var gravityY: CGFloat
    @Binding var noteLength: CGFloat
    @Binding var scale: CGFloat
    @Binding var rotationSpeed: CGFloat
    @Binding var segmentOffset: CGFloat
    @Binding var numberOfSides: CGFloat
    @Binding var isKeyboardVisible: Bool
    @Binding var isMotionEnabled: Bool
    
    let tintColor: Color
    
    var body: some View {
        HStack {
            SliderView(value: $gravityY, name: "Gravity", range: gravitySliderRange, step: smallSliderStep)
                .disabled(isMotionEnabled)
            SliderView(value: $noteLength, name: "Note Length", range: noteLengthRange, step: smallSliderStep)
        }
        .foregroundStyle(tintColor)
        HStack {
            SliderView(value: $scale, name: "Scale", range: scaleSliderRange, step: smallSliderStep)
            SliderView(value: $rotationSpeed, name: "Torque", range: torqueSliderRange, step: smallSliderStep)
        }
        .foregroundStyle(tintColor)
        HStack {
            SliderView(value: $segmentOffset, name: "Diffusion", range: spreadSliderRange, step: normalSliderStep)
            SliderView(value: $numberOfSides, name: "Vertices", range: verticesSliderRange, step: 1.0)
        }
        .foregroundStyle(tintColor)
    }
}
