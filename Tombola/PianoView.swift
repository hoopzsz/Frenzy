//
//  PianoView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import SwiftUI

struct PianoKeyPreferenceData: Equatable {
    let index: Int
    let bounds: CGRect
}

struct PianoKeyPreferenceKey: PreferenceKey {
    typealias Value = [PianoKeyPreferenceData]
    
    static var defaultValue: [PianoKeyPreferenceData] = []
    
    static func reduce(value: inout [PianoKeyPreferenceData], nextValue: () -> [PianoKeyPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}

struct PianoKeyView: View {
    
    @State private var innerStrokeDistance = 4.0
    @State private var backgroundColor = Color.black
    @State private var scale = 1.0
    @State private var innerBorderColor = Color.white
    
    @Binding var isPressed: Bool
    let color: Color
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerSize: .init(width: cornerRadius, height: cornerRadius))
            .strokeBorder(color, lineWidth: 1.0)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius - 4.0)
                    .strokeBorder(isPressed ? .white : color, lineWidth: isPressed ? 1.0 : 0.5)
                    .padding(innerStrokeDistance)
            )
            .zIndex(isPressed ? 1000 : 10)
            .padding(1.0)
            .scaleEffect(CGSize(width: 1.0, height: scale))
            .onChange(of: isPressed, initial: false) {
                withAnimation(.easeInOut(duration: 0.07)) {
                    backgroundColor = isPressed ? color : .black
                    scale = isPressed ? 0.98 : 1.0
                }
            }
    }
}

struct PianoView: View {
    
    @State private var keyData: [PianoKeyPreferenceData] = []
    @State var selectedKeys2: Set<Int> = []
    @State var lastSelectedKey: Int = -1

    @Binding var keyPress: Int?
    
    let startingKey: Int
    let numberOfKeys: Int
    
    let blackKeyWidthRatio = 0.65
    let blackKeyHeightRatio = 0.6
    
    private let blackKeyNumbers = [1, 3, 6, 8, 10]
    
//    init(startingKey: Int, numberOfKeys: Int, selectedKeys: Set<Int>) {
//        assert(!blackKeyNumbers.contains(startingKey % 12), "Starting key cannot be black")
//        self.startingKey = startingKey
//        self.numberOfKeys = numberOfKeys
////        self.selectedKeys = selectedKeys
//    }
//    init(startingKey: Int, numberOfKeys: Int, selectedKeys: Binding<Set<Int>>) {
//    init(startingKey: Int, numberOfKeys: Int, selectedKeys: Set<Int>) {
//        assert(!blackKeyNumbers.contains(startingKey % 12), "Starting key cannot be black")
//        self.startingKey = startingKey
//        self.numberOfKeys = numberOfKeys
//        self.selectedKeys = selectedKeys
//    }
         
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let numberOfWhiteKeys = (startingKey..<numberOfKeys+startingKey)
                    .filter { !blackKeyNumbers.contains($0 % 12) }
                    .count
                let whiteKeyWidth = geometry.size.width / CGFloat(numberOfWhiteKeys)
                let blackKeyWidth = whiteKeyWidth * blackKeyWidthRatio
                let blackKeyHeight = geometry.size.height * blackKeyHeightRatio
                
                ZStack {
                    HStack(spacing: 0.0) {
                        ForEach(startingKey..<startingKey + numberOfKeys, id: \.self) { index in
                            let keyNumber = index % 12
                            if !blackKeyNumbers.contains(keyNumber) {
                                PianoKeyView(isPressed: .init(get: { keyPress == index }, set: { _ in }),
                                             color: Color.orange,
                                             cornerRadius: 8.0)
                                        .background(
                                            GeometryReader { geometry in
                                                Rectangle()
                                                    .fill(Color.clear)
                                                    .preference(key: PianoKeyPreferenceKey.self,
                                                                value: [PianoKeyPreferenceData(index: index, bounds: geometry.frame(in: .named("PianoSpace")))])
                                            }
                                        )
//                                        .simultaneousGesture(TapGesture().onEnded { selectedKeys.toggle(index) })
                            }
                        }
                    }
                
                    ForEach(startingKey..<startingKey + numberOfKeys, id: \.self) { index in
                        let keyNumber = index % 12
                        let isBlackKey = blackKeyNumbers.contains(keyNumber)
                        if isBlackKey {
                            PianoKeyView(isPressed: .init(get: { keyPress == index }, set: { _ in }),
                                         color: Color.gray,
                                         cornerRadius: 8.0)
                            .background(
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .preference(key: PianoKeyPreferenceKey.self,
                                                    value: [PianoKeyPreferenceData(index: index, bounds: geometry.frame(in: .named("PianoSpace")))])
                                }
                            )
                            .frame(width: blackKeyWidth, height: blackKeyHeight)
                            .position(x: blackKeyXValue(at: index, whiteKeyWidth: whiteKeyWidth),
                                      y: blackKeyHeight * 0.5)
                        }
                    }
                }
            }
        }
        .onPreferenceChange(PianoKeyPreferenceKey.self) { value in
            keyData = value
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    keyPress = nil
                    lastSelectedKey = -1
                }
                .onChanged { drag in
                    // Reversing the array allows the overlapping view, in this case black keys, to be highlighted
                    if let data = keyData.reversed().first(where: { $0.bounds.contains(drag.location) }) {
                        // Prevent the gamescene from being spammed by the same key during dragging
                        guard data.index != lastSelectedKey else { return }
                        keyPress = data.index
                        lastSelectedKey = data.index
                    } else {
                        keyPress = nil
                        lastSelectedKey = -1
                    }
                }
        )
        .coordinateSpace(name: "PianoSpace")
    }
        
    func blackKeyXValue(at index: Int, whiteKeyWidth: CGFloat) -> CGFloat {
        let keyNumberInOctave = index % 12

        let numberOfBlackKeysSkipped = (0..<startingKey)
            .filter { blackKeyNumbers.contains($0 % 12) }
            .count

        var xOffset: CGFloat
        switch keyNumberInOctave {
        case 1:
            xOffset = whiteKeyWidth * 1
        case 3:
            xOffset = whiteKeyWidth * 2
        case 6:
            xOffset = whiteKeyWidth * 4
        case 8:
            xOffset = whiteKeyWidth * 5
        case 10:
            xOffset = whiteKeyWidth * 6
        default:
            return 0
        }
        
        let startingOctave = startingKey / 12
        let octave = (index / 12) - startingOctave
        let octaveOffset = CGFloat(octave) * 7.0 * whiteKeyWidth
        let startingKeyOffset = CGFloat(numberOfBlackKeysSkipped % 5) * whiteKeyWidth
        
        return xOffset + octaveOffset - startingKeyOffset
    }
}

#Preview {
    PianoView(keyPress: .constant(nil), startingKey: 36, numberOfKeys: 12)
}

extension Set {
    
    /// Adds an element to the Set if ithe Set does not already have it. Otherwise removes the value from the Set.
    mutating func toggle(_ element: Set.Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}
