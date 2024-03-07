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
    
//    @Published var noteOnNumber: UInt7? = nil
    
    var didReceiveMIDIEvent: (MIDIEvent) -> Void = { _ in }
    
    // MARK: - Connections
    
    static let inputConnectionName = "TestApp Input Connection"
    static let outputConnectionName = "TestApp Output Connection"
    
    private func setupConnections() {
        guard let midiManager else { return }
        
        do {
            // "IDAM MIDI Host" is the name of the MIDI input and output that iOS creates
            // on the iOS device once a user has clicked 'Enable' in Audio MIDI Setup on the Mac
            // to establish the USB audio/MIDI connection to the iOS device.
//            
            print("Creating MIDI input connection.")
            try midiManager.addInputConnection(
                to: .outputs(matching: [.name("IDAM MIDI Host")]),
                tag: Self.inputConnectionName,
                receiver: .events(options: [.bundleRPNAndNRPNDataEntryLSB, .filterActiveSensingAndClock], { [weak self] events, timestamp, outputEndpoint in
                    if let event = events.first {
                        self?.didReceiveMIDIEvent(event)
//                        print("⚠️ received event: \(event)")
//                        switch event {
//                        case .noteOn(let noteOnData):
//                            self.noteOnNumber = noteOnData.note.number
//                        default:
//                            break
//                        }
                    }
                })
//                receiver: .eventsLogging(options: [
//                    .bundleRPNAndNRPNDataEntryLSB,
//                    .filterActiveSensingAndClock
//                ])
            )
            
            print("Creating MIDI output connection.")
//            try midiManager.addOutputConnection(
//                to: .inputs(matching: [.name("IDAM MIDI Host")]),
//                tag: Self.outputConnectionName
//            )
            
            try midiManager.addOutputConnection(to: .allInputs, tag: Self.outputConnectionName)
            
        } catch {
            print("Error creating MIDI output connection:", error.localizedDescription)
        }
    }
    
    /// Convenience accessor for created MIDI Output Connection.
    var outputConnection: MIDIOutputConnection? {
        midiManager?.managedOutputConnections[Self.outputConnectionName]
    }
    
    func sendNoteOn(_ note: UInt7) {
//        print("Sending note ON (\(note))")
        try? outputConnection?.send(event: .noteOn(
            note,
            velocity: .midi1(127),
            channel: 0
        ))
    }
    
    func sendNoteOff(_ note: UInt7) {
//        print("Sending note OFF (\(note))")
        try? outputConnection?.send(event: .noteOff(
            note,
            velocity: .midi1(0),
            channel: 0
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
