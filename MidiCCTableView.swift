//
//  MidiCCTableView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-17.
//

import SwiftUI

struct MidiCCRow: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let cc: Int
}

enum MidiCC: String, CaseIterable {
    
    case gravity
    case unknown
    case scale
    case torque
    case divergence
    case vertices
    
    var cc: Int {
        switch self {
        case .gravity:
            13
        case .unknown:
            14
        case .scale:
            15
        case .torque:
            16
        case .divergence:
            17
        case .vertices:
            18
        }
    }
    
    var row: MidiCCRow {
        MidiCCRow(name: rawValue.capitalized, cc: cc)
    }
}

struct MidiCCTableView: View {
    
    let ccValues = MidiCC.allCases.map { $0.row }
    
    var body: some View {
        VStack {
            ForEach(MidiCC.allCases, id: \.self) { cc in
                HStack {
                    Text("\(cc.rawValue.capitalized)")
                    Text("...")
                    Text("\(cc.cc)")
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    MidiCCTableView()
}
