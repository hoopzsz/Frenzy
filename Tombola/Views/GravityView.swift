//
//  GravityView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

struct GravityView: View {
    
    @Binding var gravityX: CGFloat
    @Binding var gravityY: CGFloat
    
    private let numberOfSides = 12
        
    var body: some View {
        HStack {
            VStack {
                Spacer()
                ZStack {
//                    GeometryReader { geometry in
                        GravityViewShape(numberOfSides: numberOfSides)
                            .stroke(Color.gray, lineWidth: 0.5)
                            .fill(.clear)
                        
                        let offset = (gravityX, (gravityY - 3.0) * 4)
//                        let frame = geometry.frame(in: .local)
                        // Draw a path from the center to the circle
//                        Path { path in
//                            path.move(to: CGPoint(x: frame.midX, y: frame.midY))
//                            path.addLine(to: CGPoint(x: offset.0, y: offset.1))
//                        }
//                        .stroke(Color.gray, lineWidth: 0.5)
                        Circle()
                            .frame(width: 2.0, height: 2.0)
                            .offset(x: offset.0, y: offset.1) // normalize from slider value by subtracting 3.0, then visually exagerrate by multiplying 4
                            .foregroundStyle(.orange)
//                    }
//                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
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
