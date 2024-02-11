//
//  TombolaApp.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-09.
//

import MIDIKitIO
import SwiftUI

@main
struct TombolaApp: App {
    
    @State var tintColor: Color = .orange
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(tintColor)
        }
    }
}

#Preview {
    ContentView()
        .tint(.orange)
}
