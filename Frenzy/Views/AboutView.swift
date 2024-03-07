//
//  AboutView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-17.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("""
        Frenzy is a MIDI sequencer inspired by the OP-1 Tombola sequencer.
        
        This app is not a synthesizer or drum machine, it does not create sounds. It creates MIDI note events to play your synthesizers and drum machines, virtual or hardware.
        """)
            .padding()

            Link("Learn more about MIDI here.", destination: URL(string: "https://en.wikipedia.org/wiki/MIDI")!)
                .padding()
        }
        .fontWeight(.medium)
        .italic()
        .environment(\.colorScheme, .dark)
        .padding()
    }
}

#Preview {
    AboutView()
}
