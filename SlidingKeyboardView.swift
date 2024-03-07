//
//  SlidingKeyboardView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-06.
//

import SwiftUI

struct SlidingKeyboardView: View {
    
    @Binding var keyboardOffset: CGFloat
    @Binding var keyPress: Int?
    @Binding var globalTintColor: Color
    @Binding var secondaryTintColor: Color
    
    let idealHeight: CGFloat //geometry.size.height * 0.25
    
    var body: some View {
        GeometryReader { geometry in
            LazyVStack {
                LazyHStack {
                    PianoView(keyPress: $keyPress,
                              startingKey: 0,
                              numberOfKeys: 108,
                              whiteKeyColor: $globalTintColor,
                              blackKeyColor: $secondaryTintColor)
                    .frame(width: geometry.size.width * 9.0, height: idealHeight)
                    .offset(x: self.keyboardOffset * -1.0)
                }
                let min = geometry.size.width * -4.0
                Slider(value: $keyboardOffset, in: min...(max(1.0, geometry.size.width * 4.0)), step: 1.0)
            }
        }
    }
}
