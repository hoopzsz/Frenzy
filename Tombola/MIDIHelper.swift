//
//  MIDIHelper.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2023 Steffan Andrews • Licensed under MIT License
//

import MIDIKitIO
import SwiftUI

/// Receiving MIDI happens as an asynchronous background callback. That means it cannot update
/// SwiftUI view state directly. Therefore, we need a helper class that conforms to
/// `ObservableObject` which contains `@Published` properties that SwiftUI can use to update views.
final class MIDIHelper: ObservableObject {
    
    private weak var midiManager: ObservableMIDIManager?
    
    public init() { }
    
    public func setup(midiManager: ObservableMIDIManager) {
        self.midiManager = midiManager
        
        do {
            print("Starting MIDI services.")
            try midiManager.start()
        } catch {
            print("Error starting MIDI services:", error.localizedDescription)
        }
        
        setupConnections()
    }
        
    var didReceiveMIDIEvent: (MIDIEvent) -> Void = { _ in }
    
    var inputChannel: Int = 0
    var outputChannel: UInt4 = 0
    
    // MARK: - Connections
    
    static let inputConnectionName = "TestApp Input Connection"
    static let outputConnectionName = "TestApp Output Connection"
    
    private func setupConnections() {
        guard let midiManager else { return }
        
        do {
            // "IDAM MIDI Host" is the name of the MIDI input and output that iOS creates
            // on the iOS device once a user has clicked 'Enable' in Audio MIDI Setup on the Mac
            // to establish the USB audio/MIDI connection to the iOS device.
            
//            print("Creating MIDI input connection.")
//            try midiManager.addInputConnection(
//                to: .outputs(matching: [.name("IDAM MIDI Host")]),
//                tag: Self.inputConnectionName,
//                receiver: .events(options: [.bundleRPNAndNRPNDataEntryLSB, .filterActiveSensingAndClock], { [weak self] events, timestamp, outputEndpoint in
//                    events
//                        .compactMap { $0 }
//                        .forEach {
//                            self?.didReceiveMIDIEvent($0)
//                        }
//                })
//            )
//            
//            print("Creating MIDI output connection.")
//            try midiManager.addOutputConnection(
//                to: .allInputs,
//                tag: Self.outputConnectionName
//            )
            
            do {
                try midiManager.addInputConnection(
                    to: .allOutputs, // auto-connect to all outputs that may appear
                    tag: "Listener",
                    filter: .owned(), // don't allow self-created virtual endpoints
                    receiver: .events(options: [.bundleRPNAndNRPNDataEntryLSB, .filterActiveSensingAndClock], { [weak self] events, timestamp, outputEndpoint in
                        events
                            .compactMap { $0 }
                            .filter { ($0.channel ?? 1) == (self?.inputChannel ?? -1) }
                            .forEach {
                                self?.didReceiveMIDIEvent($0)
                            }
                    })
                )
            } catch {
                print(
                    "Error setting up managed MIDI all-listener connection:",
                    error.localizedDescription
                )
            }
            
            // set up a broadcaster that can send events to all MIDI inputs
            
            do {
                try midiManager.addOutputConnection(
                    to: .allInputs, // auto-connect to all inputs that may appear
                    tag: "Broadcaster",
                    filter: .owned() // don't allow self-created virtual endpoints
                )
            } catch {
                print(
                    "Error setting up managed MIDI all-listener connection:",
                    error.localizedDescription
                )
            }
            
        } 
//        catch {
//            print("Error creating MIDI output connection:", error.localizedDescription)
//        }
    }
    
    /// Convenience accessor for created MIDI Output Connection.
    var outputConnection: MIDIOutputConnection? {
        midiManager?.managedOutputConnections[Self.outputConnectionName]
    }
    
    func sendNoteOn(_ note: UInt7, velocity: Int, noteOffDelay: Double = 0.1) {
        let conn = midiManager?.managedOutputConnections["Broadcaster"]
        do {
            let v = min(127, velocity)
            print("velocity: \(v)")
            try conn?.send(event: .noteOn(note, velocity: .midi1(UInt7(v)), channel: outputChannel))
        } catch {
            print("⚠️ \(error.localizedDescription)")
        }
        
        if noteOffDelay > 0.0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + noteOffDelay) { [weak self] in
                self?.sendNoteOff(note)
            }
        }
    }
    
    func sendNoteOff(_ note: UInt7) {
        let conn = midiManager?.managedOutputConnections["Broadcaster"] ?? outputConnection

        try? outputConnection?.send(event: .noteOff(
            note,
            velocity: .midi1(127),
            channel: outputChannel
        ))
    }
    
    func sendCC1() {
        try? outputConnection?.send(event: .cc(
            1,
            value: .midi1(64),
            channel: 0
        ))
    }
}
