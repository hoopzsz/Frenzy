//
//  NoteIndicatorView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

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
