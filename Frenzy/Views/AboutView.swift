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
        Frenzy is a MIDI sequencer that uses objects in a physics environment to generate random patterns of notes.
        
        This app is not a synthesizer or drum machine, it does not create sounds. It creates MIDI note events to play your synthesizers and drum machines, virtual or hardware. However, you can enable a tone generator to produce sounds to help you understand and use the app without connecting to other apps or devices.
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
