//
//  ControlsView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-03-06.
//

import SwiftUI

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
        VStack {
            HStack {
                SliderView(value: $gravityY, name: "Gravity", range: 0.0...1.0, step: 0.01)
                    .disabled(isMotionEnabled)
                SliderView(value: $noteLength, name: "Note length", range: 0.1...1.0, step: 0.01)
            }
            .foregroundStyle(tintColor)
            HStack {
                SliderView(value: $scale, name: "Scale", range: 0.1...1.0, step: 0.01)
                SliderView(value: $rotationSpeed, name: "Torque", range: 0.0...10.0, step: 0.01)
            }
            .foregroundStyle(tintColor)
            HStack {
                SliderView(value: $segmentOffset, name: "Diffusion", range: 0.0...180.0, step: 1.0)
                SliderView(value: $numberOfSides, name: "Vertices", range: 2.0...13.0, step: 1.0)
            }
            .foregroundStyle(tintColor)
        }
    }
}
