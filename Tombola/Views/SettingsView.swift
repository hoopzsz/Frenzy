//
//  SettingsView.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var midiChannelOutput: Int = 1
    @State var midiChannelInput: Int = 1
    
    @Binding var globalTintColor: Color
    @Binding var secondaryTintColor: Color
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                HStack {
                    Spacer()
                    Button("", systemImage: "xmark") {
                        dismiss()
                    }
                    .padding()
                }
                ColorPicker("Primary color", selection: $globalTintColor)
                    .foregroundColor(globalTintColor)
                    .padding()
                ColorPicker("Secondary color", selection: $secondaryTintColor)
                    .foregroundColor(secondaryTintColor)
                    .padding()
                Spacer()
            }
        }
        .italic()
        .fontWeight(.medium)
        .multilineTextAlignment(.leading)
        .tint(self.globalTintColor)
    }
}

#Preview {
    SettingsView(globalTintColor: .constant(.orange), secondaryTintColor: .constant(.gray))
}
