//
//  SliderView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

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
                .multilineTextAlignment(.leading)
                .offset(x: 1, y: -11.0)
            Slider(value: $value, in: range, step: step, onEditingChanged: { _ in })
        }
    }
}

#Preview {
    SliderView(value: .constant(0.1), name: "Divergence", range: 0.0...1.0, step: 0.01)
}
