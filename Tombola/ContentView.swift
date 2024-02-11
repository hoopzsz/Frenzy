//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI
import SpriteKit

struct SliderView: View {
    
    @Binding var value: CGFloat
    
    let name: String
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            Text(name.uppercased())
                .italic()
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .offset(y: -10.0)
            Slider(value: $value, in: range, step: step, onEditingChanged: { _ in })
        }
    }
}

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    
    @State var isInternalSoundEnabled: Bool = true
    
    @State var presentSettings: Bool = false
    
//     private var midiManager = ObservableMIDIManager(
//        clientName: "TestAppMIDIManager",
//        model: "TestApp",
//        manufacturer: "MyCompany"
//    )
    
    @ObservedObject private var midiHelper = MIDIHelper()
    
    private let gravitySliderRange: ClosedRange<CGFloat> = 0.0...6.0
    private let massSliderRange: ClosedRange<CGFloat> = 0.0...100.0
    private let scaleSliderRange: ClosedRange<CGFloat> = 0.2...2.0
    private let torqueSliderRange: ClosedRange<CGFloat> = 0.0...10.0
    private let spreadSliderRange: ClosedRange<CGFloat> = 0.0...180.0
    private let verticesSliderRange: ClosedRange<CGFloat> = 2.0...13.0
    
    private let smallSliderStep = 0.01
    private let normalSliderStep = 1.0
    
    var body: some View {
        NavigationStack {
            DynamicStack {
                GeometryReader { geometry in
                    self.updateSize(geometry.size)
                    SpriteView(scene: gameScene,
                               debugOptions: [ ])
                }
                VStack {
                    HStack {
                        SliderView(value: $gameScene.gravity, name: "Gravity", range: gravitySliderRange, step: smallSliderStep)
                        SliderView(value: $gameScene.mass, name: "Mass", range: massSliderRange, step: normalSliderStep)
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
                        .padding(4.0)
                        .aspectRatio(2.25, contentMode: .fit)
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
                        //                        Toggle(isOn: $gameScene.isMotionEnabled) {
                        //                            Image(systemName: gameScene.isMotionEnabled ? "m.square" : "m.square.fill")
                        //                        }
                        //                        Toggle(isOn: $isInternalSoundEnabled) {
                        //                            Image(systemName: isInternalSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle")
                        //                        }
                        //                        Toggle(isOn: $presentSettings) {
                        //                            Image(systemName: "gearshape.fill")
                        //                        }
                        Button("Accelerometer",
                               systemImage: gameScene.isMotionEnabled ? "m.square.fill" : "m.square") {
                            gameScene.isMotionEnabled.toggle()
                        }
                        Button("Audio", systemImage: isInternalSoundEnabled ? "speaker.wave.2.circle.fill" : "speaker.slash.circle") {
                            isInternalSoundEnabled.toggle()
                        }
                        Button("Settings", systemImage: "gearshape.fill") {

                        }
                        
                    }
                }
            }
            .tint(.orange)
        }
        .onShake {
            gameScene.didShake.toggle()
        }
        
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

// The notification we'll send when a shake gesture happens.
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

//  Override the default behavior of shake gestures to send our notification instead.
extension UIWindow {
     open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
     }
}

// A view modifier that detects shaking and calls a function of our choosing.
struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

// A View extension to make the modifier easier to use.
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}
