//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI
import SpriteKit

private let gravitySliderRange: ClosedRange<CGFloat> = 0.0...6.0
private let massSliderRange: ClosedRange<CGFloat> = 0.0...1.0
private let scaleSliderRange: ClosedRange<CGFloat> = 0.1...1.5
private let torqueSliderRange: ClosedRange<CGFloat> = 0.0...10.0
private let spreadSliderRange: ClosedRange<CGFloat> = 0.0...180.0
private let verticesSliderRange: ClosedRange<CGFloat> = 2.0...13.0

private let smallSliderStep = 0.01
private let normalSliderStep = 1.0

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    
    @State var isInternalSoundEnabled: Bool = true
    
    @State var presentSettings: Bool = false

    var body: some View {
        NavigationStack {
            DynamicStack {
                GeometryReader { geometry in
                    self.updateSize(geometry.size)
                    ZStack {
                        SpriteView(scene: gameScene,
                                   debugOptions: [])
//                                   debugOptions: [.showsFPS, .showsNodeCount, .showsFields, .showsPhysics])
                        VStack {
                            Spacer()
                            HStack {
                                GravityView(gravityX: .constant(0.0), gravityY: $gameScene.gravity)
                                Spacer()
                            }
                        }
                        .padding(8.0)
                    
                        NoteIndicatorView(startingNote: 0, numberOfNotes: 132, notes: notesFromNodes($gameScene.noteDots.wrappedValue))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                        SpawnPositionView()
                    }
                    .aspectRatio(1.0, contentMode: .fit)
                }
                VStack {
                    HStack {
                        SliderView(value: $gameScene.gravity, name: "Gravity", range: gravitySliderRange, step: smallSliderStep)
                        SliderView(value: $gameScene.mass, name: "???", range: massSliderRange, step: smallSliderStep)
                    }
                    HStack {
                        SliderView(value: $gameScene.scale, name: "Scale", range: scaleSliderRange, step: smallSliderStep)
                        SliderView(value: $gameScene.rotationSpeed, name: "Torque", range: torqueSliderRange, step: smallSliderStep)
                    }
                    HStack {
                        SliderView(value: $gameScene.segmentOffset, name: "Spread", range: spreadSliderRange, step: normalSliderStep)
                        SliderView(value: $gameScene.numberOfSides, name: "Vertices", range: verticesSliderRange, step: normalSliderStep)
                    }
                    PianoView(keyPress: $gameScene.keyPress, startingKey: 36, numberOfKeys: 12)
                        .aspectRatio(2.5, contentMode: .fit)
                }
                .padding(8.0)
            }
            .background(Color.black.ignoresSafeArea())
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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Button("Accelerometer",
                               systemImage: gameScene.isMotionEnabled ? "m.square.fill" : "m.square") {
                            gameScene.isMotionEnabled.toggle()
                        }
                        Button("Audio", systemImage: isInternalSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle") {
                            isInternalSoundEnabled.toggle()
                        }
                        Button("Settings", systemImage: "gearshape.fill") {
                            self.presentSettings.toggle()
                        }
                    }
                }
            }
            .tint(.orange)
        }
        .onShake {
//            gameScene.didShake.toggle()
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

struct SpawnPositionShape: Shape {
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

struct SpawnPositionView: View {
    
    var body: some View {
        ZStack {
            SpawnPositionShape()
                .stroke(Color.gray, lineWidth: 0.5)
                .frame(width: 10, height: 10)
            Text("spawn")
                .font(.system(size: 9.0))
                .italic()
//                .fontWeight(.medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .offset(x: 21.0, y: 0.5)
        }
    }
}

#Preview {
    ContentView()
}
