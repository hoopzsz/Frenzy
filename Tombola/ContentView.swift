//
//  ContentView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI
import SpriteKit

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

struct GravityViewShape: Shape {
    
    let numberOfSides: Int
    
    func path(in rect: CGRect) -> Path {
        var points = calculatePolygonCoordinates(numberOfSides)
            .map {
                CGPoint(x: $0.0 * rect.width * 0.5 + rect.midX, y: ($0.1 * rect.height * 0.5) + rect.midY)
            }
        
        var path = Path()
        
        let origin = points.removeFirst()
        path.move(to: origin)
        points.forEach {
            path.addLine(to: $0)
        }
        path.addLine(to: origin) // close the shape
        
        return path
    }
}

struct GravityView: View {
    
    @Binding var gravityX: CGFloat
    @Binding var gravityY: CGFloat
    
    private let numberOfSides = 12
        
    var body: some View {
        HStack {
            VStack {
                Spacer()
                ZStack {
                    GravityViewShape(numberOfSides: numberOfSides)
                        .stroke(Color.gray, lineWidth: 0.5)
                        .fill(.clear)
                    Circle()
                        .frame(width: 2.0, height: 2.0)
                        .offset(x: gravityX, y: (gravityY - 3.0) * 4) // normalize from slider value by subtracting 3.0, then visually exagerrate by multiplying 4
                        .foregroundStyle(.red)
                }
                .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            VStack {
                Spacer()
                let x = String(format: "%.2f", gravityX)
                let y = String(format: "%.2f", gravityY - 3.0)
                Text("\(x), \(y)")
                    .font(.system(size: 8))
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(.gray)
        }
//            let x = String(format: "%.0f", gravityX)
//            let y = String(format: "%.0f", gravityY - 3.0)
//            Text("g=(\(x),\(y))")
//                .font(.system(size: 8))
//                .multilineTextAlignment(.trailing)
//                .foregroundStyle(.gray)
//                .offset(x: geometry.size.width - 45, y: 50)
    }
}

struct NoteIndicatorView: View {
    let startingNote: Int
    let numberOfNotes: Int
    
    let notes: [Int]
    
    var body: some View {
        VStack(spacing: 1.0) {
            ForEach(startingNote...startingNote + numberOfNotes, id: \.self) { note in
                HStack(spacing: 1.0) {
                    let numberOfSpecificNote = notes
                        .filter { $0 == note }
                        .count
                    
                    if numberOfSpecificNote == 0 {
                        // Make a dummy view for layout purposes
                        Circle()
                            .fill(.clear)
                            .frame(width: 2.0, height: 2.0)
                    } else {
                        ForEach(0..<numberOfSpecificNote, id: \.self) { _ in
                            Circle()
                                .fill(.gray)
                                .frame(width: 2.0, height: 2.0)
                        }
                        .opacity(numberOfSpecificNote == 0 ? 0 : 1.0)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct ContentView: View {
    
    @StateObject var gameScene = GameScene()
    
    @State var isInternalSoundEnabled: Bool = true
    
    @State var presentSettings: Bool = false

//    @ObservedObject private var midiHelper = MIDIHelper()
    
    private let gravitySliderRange: ClosedRange<CGFloat> = 0.0...6.0
    private let massSliderRange: ClosedRange<CGFloat> = 0.0...1.0
    private let scaleSliderRange: ClosedRange<CGFloat> = 0.1...1.5
    private let torqueSliderRange: ClosedRange<CGFloat> = 0.0...10.0
    private let spreadSliderRange: ClosedRange<CGFloat> = 0.0...180.0
    private let verticesSliderRange: ClosedRange<CGFloat> = 2.0...13.0
    
    private let smallSliderStep = 0.01
    private let normalSliderStep = 1.0
    
    func notesFromNodes(_ nodes: [NoteDot]) -> [Int] {
        nodes.map { $0.noteValue }
    }
    
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
                    }
                    .aspectRatio(1.0, contentMode: .fit)
                }
                VStack {
                    HStack {
                        SliderView(value: $gameScene.gravity, name: "Gravity", range: gravitySliderRange, step: smallSliderStep)
                        SliderView(value: $gameScene.mass, name: "Mass", range: massSliderRange, step: smallSliderStep)
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
                            self.presentSettings.toggle()
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
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                hStack
            } else {
                vStack
            }
        }
//        switch sizeClass {
//        case .regular:
//            hStack
//        case .compact, .none:
//            vStack
//        @unknown default:
//            vStack
//        }
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
