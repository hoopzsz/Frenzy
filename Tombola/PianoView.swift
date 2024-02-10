//
//  PianoView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import SwiftUI

struct PianoKeyView: View {
    
    @State var keyColor: Color
    let selectionColor = Color.blue
    let isSelected: Bool
    let cornerRadius: CGFloat
    private let originalKeyColor: Color
    
    init(keyColor: Color, isSelected: Bool, cornerRadius: CGFloat) {
        self.keyColor = keyColor
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.originalKeyColor = keyColor
    }

    var body: some View {
        RoundedRectangle(cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
            .stroke(.black)
            .background(keyColor)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: cornerRadius, height: cornerRadius)))
            .onChange(of: isSelected, initial: true, {
                withAnimation {
                    keyColor = isSelected ? selectionColor : originalKeyColor
                }
            })
            .animation(.easeInOut(duration: 0.07), value: keyColor)
    }
}

struct PianoView: View {
            
//    @State private var keyData: [CardPreferenceData] = []
    @Binding var selectedKeys: Set<Int>

    let startingKey: Int
    let numberOfKeys: Int
    
    let blackKeyWidthRatio = 0.6
    let blackKeyHeightRatio = 0.5
    
    private let blackKeyNumbers = [1, 3, 6, 8, 10]
    
//    init(startingKey: Int, numberOfKeys: Int, selectedKeys: Set<Int>) {
//        assert(!blackKeyNumbers.contains(startingKey % 12), "Starting key cannot be black")
//        self.startingKey = startingKey
//        self.numberOfKeys = numberOfKeys
////        self.selectedKeys = selectedKeys
//    }
    init(startingKey: Int, numberOfKeys: Int, selectedKeys: Binding<Set<Int>>) {
        assert(!blackKeyNumbers.contains(startingKey % 12), "Starting key cannot be black")
        self.startingKey = startingKey
        self.numberOfKeys = numberOfKeys
        self._selectedKeys = selectedKeys
    }
         
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
                        ForEach(startingKey..<numberOfKeys+startingKey, id: \.self) { index in
                            let keyNumber = index % 12
                            if !blackKeyNumbers.contains(keyNumber) {
                                ZStack {
                                    PianoKeyView(keyColor: Color.white, isSelected: selectedKeys.contains(index), cornerRadius: 5.0)
                                        .background(
                                            GeometryReader { geometry in
                                                Rectangle()
                                                    .fill(Color.clear)
//                                                    .preference(key: CardPreferenceKey.self,
//                                                                value: [CardPreferenceData(index: index, bounds: geometry.frame(in: .named("GameSpace")))])
                                            }
                                        )
                                        .onTapGesture {
                                            $selectedKeys.wrappedValue.insert(index)
//                                            print($selectedKeys.wrappedValue)
                                        }
                                }
                            }
                        }
                    }
                
                    ForEach(startingKey..<(startingKey + numberOfKeys), id: \.self) { index in
                        let keyNumber = index % 12
                        let isBlackKey = blackKeyNumbers.contains(keyNumber)
                        if isBlackKey {
                            ZStack {
                                PianoKeyView(keyColor: Color.black, isSelected: selectedKeys.contains(index), cornerRadius: 5.0)
                            }
                            .background(
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
//                                    [CardPreferenceData(index: index, bounds: CGRect(x: blackKeyXValue(at: index, whiteKeyWidth: whiteKeyWidth), y: blackKeyHeight * 0.5, width: blackKeyWidth, height: blackKeyHeight))]
//                                        .preference(key: CardPreferenceKey.self,
//                                                    value: [CardPreferenceData(index: index, bounds: geometry.frame(in: .named("GameSpace")))])
                                }
                            )
                            .frame(width: blackKeyWidth, height: blackKeyHeight)
                            .position(x: blackKeyXValue(at: index, whiteKeyWidth: whiteKeyWidth),
                                      y: blackKeyHeight * 0.5)

                            .onTapGesture {
//                                $selectedKeys.wrappedValue.toggle(index)
                                $selectedKeys.wrappedValue.insert(index)
//                                print($selectedKeys.wrappedValue)
                            }
                        }
                    }
                }
            }
        }
//        .onPreferenceChange(CardPreferenceKey.self) { value in
//            keyData = value
//        }
        .gesture(
            DragGesture()
                .onEnded { _ in
                    selectedKeys = []
//                    midiHelper.sendNoteOff(UInt7(lastSelectedIndex))
                }
                .onChanged { drag in
//                    if let data = keyData.first(where: { $0.bounds.contains(drag.location) }) {
//                        guard selectedKeys != [data.index] else { return }
//                        selectedKeys = [data.index]
//                        lastSelectedIndex = data.index
//                        midiHelper.sendNoteOn(UInt7(data.index))
//                    } else {
//                        midiHelper.sendNoteOff(UInt7(demoValue + 36))
//                        selectedKeys = []
//                    }
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
//        let modulo = startingKey % 2 == 0 ? 4 : 5
        let startingKeyOffset = CGFloat(numberOfBlackKeysSkipped % 5) * whiteKeyWidth
        
        return xOffset + octaveOffset - startingKeyOffset
    }
}

#Preview {
    PianoView(startingKey: 36, numberOfKeys: 12, selectedKeys: .constant([]))
}
