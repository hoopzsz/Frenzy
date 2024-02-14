//
//  SpawnPositionView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

struct SpawnPositionShape: Shape {
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

struct SpawnPositionView: View {
    
    var body: some View {
        ZStack {
            SpawnPositionShape()
                .stroke(lineWidth: 0.5)
//                .stroke(Color.gray, lineWidth: 0.5)
                .frame(width: 10, height: 10)
            Text("spawn")
                .font(.system(size: 9.0))
                .italic()
//                .fontWeight(.medium)
//                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .offset(x: 21.0, y: 0.25)
        }
    }
}
#Preview {
    SpawnPositionView()
}
