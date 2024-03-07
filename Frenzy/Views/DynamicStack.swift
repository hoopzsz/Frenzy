//
//  DynamicStack.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

/// A `View` that uses either a `VStack` or `HStack` depending on the orientation of the device
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
