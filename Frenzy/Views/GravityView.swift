//
//  GravityView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

struct GravityView: View {
    
    @Binding var gravityX: CGFloat
    @Binding var gravityY: CGFloat
    @Binding var strokeColor: Color
    @Binding var indicatorColor: Color
    
    private let numberOfSides = 8
    
    var body: some View {
        let adjustedGravityX = (gravityX - 0.5)// * 5.0
        let adjustedGravityY = (gravityY - 0.5)// * 5.0
        HStack {
            VStack {
                Spacer()
                ZStack {
                    GravityViewShape(numberOfSides: numberOfSides)
                        .stroke(strokeColor, lineWidth: 0.5)
                        .fill(Color.clear)
                    
                    let offset = (adjustedGravityX, adjustedGravityY)
                    Circle()
                        .frame(width: 2.0, height: 2.0)
                        // Exagerate the visual appearance with the 20x multiplier
                        .offset(x: offset.0 * 15.0, y: offset.1 * 20.0)
                        .foregroundStyle(indicatorColor)
                }
                .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            VStack {
                Spacer()
                // Multiply each value by 2 so the values read from `-1.0...1.0`
                let x = String(format: "%.2f", adjustedGravityX * 2.0)
                let y = String(format: "%.2f", adjustedGravityY * 2.0)
                Text("x: \(x)\ny: \(y)")
                    .font(.system(size: 8))
                    .multilineTextAlignment(.leading)
            }
            .foregroundColor(strokeColor)
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
