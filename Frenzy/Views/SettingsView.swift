//
//  SettingsView.swift
//  Frenzy
//
//  Created by Daniel Hooper on 2024-02-13.
//

import SwiftUI



struct SettingsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var midiChannelOutput: Int
    @Binding var midiChannelInput: Int
    @Binding var isVelocityFixed: Bool
    
    @Binding var globalTintColor: Color
    @Binding var secondaryTintColor: Color
    @Binding var isKeyboardVisible: Bool
    @Binding var collisionSensitiviy: CollisionSensitivity
    
    var body: some View {
        NavigationView {
            Form() {
                Section("Bluetooth") {
                    NavigationLink(
                        destination: BluetoothMIDIPeripheralView()
                            .navigationTitle("MIDI Peripheral Config")
                            .navigationBarTitleDisplayMode(.inline)
                    ) {
                        Text("Connect Bluetooth")
                    }
                }
                
                Section("MIDI") {
                    Stepper("Input channel: \(midiChannelInput + 1)",
                            value: $midiChannelInput,
                            in: 0...15,
                            step: 1,
                            onEditingChanged: { _ in })
                    
                    Stepper("Output channel: \(midiChannelOutput + 1)",
                            value: $midiChannelOutput,
                            in: 0...15,
                            step: 1,
                            onEditingChanged: { _ in })
                }
                
                Section("Physics") {
                    Toggle(isOn: $isVelocityFixed) {
                        Text("Fixed velocity")
                    }
                    Stepper("Impact sensitivity: \(collisionSensitiviy.description)",
                            value: .init(get: {
                        collisionSensitiviy.rawValue
                    }, set: {
                        collisionSensitiviy = CollisionSensitivity(rawValue: $0) ?? .medium
                    }),
                            in: 0...2,
                            step: 1,
                            onEditingChanged: { _ in })
                }

                Section("MIDI CC") {
                    NavigationLink(
                        destination: MidiCCTableView()
                            .navigationTitle("MIDI CC Values")
                            .navigationBarTitleDisplayMode(.inline)
                    ) {
                        Text("View MIDI CC values")
                    }
                }
                
                Section("Customization") {
                    ColorPicker("Primary color", selection: $globalTintColor)
                        .foregroundColor(globalTintColor)
                    ColorPicker("Secondary color", selection: $secondaryTintColor)
                        .foregroundColor(secondaryTintColor)
                }
                
                Section() {
                    NavigationLink(
                        destination: AboutView()
                            .tint(self.globalTintColor)
                            .navigationTitle("About")
                            .navigationBarTitleDisplayMode(.inline)
                    ) {
                        Text("About this app")
                    }
                }
            }
            .italic()
            .fontWeight(.medium)
            .multilineTextAlignment(.leading)
            .toolbar() {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .tint(self.globalTintColor)
        }
        .tint(self.globalTintColor)
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    SettingsView(midiChannelOutput: .constant(0),
                 midiChannelInput: .constant(0),
                 isVelocityFixed: .constant(true),
                 globalTintColor: .constant(.orange),
                 secondaryTintColor: .constant(.gray),
                 isKeyboardVisible: .constant(true),
                 collisionSensitiviy: .constant(.low))
}
    
import CoreAudioKit

struct BluetoothMIDIView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> BTMIDICentralViewController {
        BTMIDICentralViewController()
    }
    
    func updateUIViewController(
        _ uiViewController: BTMIDICentralViewController,
        context: Context
    ) { }
    
    typealias UIViewControllerType = BTMIDICentralViewController
}

class BTMIDICentralViewController: CABTMIDICentralViewController {
    var uiViewController: UIViewController?
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
         let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneAction)
        )
        
        navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc
    public func doneAction() {
        uiViewController?.dismiss(animated: true, completion: nil)
    }
}

struct BluetoothMIDIPeripheralView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BTMIDIPeripheralViewController {
        BTMIDIPeripheralViewController()
    }
    
    func updateUIViewController(
        _ uiViewController: BTMIDIPeripheralViewController,
        context: Context
    ) { }
    
    typealias UIViewControllerType = BTMIDIPeripheralViewController
}

class BTMIDIPeripheralViewController: CABTMIDILocalPeripheralViewController {
    var uiViewController: UIViewController?
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let doneButton = UIBarButtonItem(
           barButtonSystemItem: .done,
           target: self,
           action: #selector(doneAction)
       )
       
       navigationItem.rightBarButtonItem = doneButton
    }
    
    @objc
    public func doneAction() {
        uiViewController?.dismiss(animated: true, completion: nil)
    }
}
