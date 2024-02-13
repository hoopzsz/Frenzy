//
//  GameScene.swift
//  Line Square Dot
//
//  Created by Daniel Hooper on 2018-09-20.
//  Copyright © 2018 danielhooper. All rights reserved.
//

import CoreMotion
import MIDIKitIO
import SpriteKit

final class GameScene: SKScene, ObservableObject {
    
    var noteCollection: Set<Int> = []
    
    var noteFiringTimeWindow = 0.1
    var previousTime: TimeInterval = .zero
    
    let bpm = 120.0
    
    var didShake = false {
        didSet {
//            print("⚠️ Shake detected: \(didShake)")
//            noteDots.forEach {
//                if let physicsBody = $0.physicsBody {
//                    physicsBody.velocity = CGVector(dx: physicsBody.velocity.dx * -1,
//                                                    dy: physicsBody.velocity.dy * -1)
//                }
//            }
        }
    }
    
    @Published var gravity: CGFloat = 3.3 {
        didSet {
            setGravity(gravity)
        }
    }
    
    func setGravity(_ gravity: CGFloat) {
        let normalizedGravity = (gravity - 3) * -1 // normalize to -3 to 3.0, then reverse
        physicsWorld.gravity = CGVector(dx: 0.0, dy: normalizedGravity)
    }
    
    @Published var isMotionEnabled: Bool = false {
        didSet {
            print("⚠️ isMotionEnabled didSet: \(isMotionEnabled)")
            if isMotionEnabled {
                // Handled by update method
            } else {
                setGravity(gravity)
            }
        }
    }
    
    @Published var mass: CGFloat = 0.0 {
        didSet {
            noteDots.forEach {
                $0.physicsBody?.linearDamping = mass
                $0.physicsBody?.angularDamping = mass
            }
        }
    }
    
    var keyPress: Int? {
        didSet {
            if let keyPress = keyPress {
                makeNoteDot(keyPress)
            }
        }
    }
    
    var r: CGFloat = 0
    
    @Published var rotationSpeed: CGFloat = 5.5
    
    @Published var segmentOffset: CGFloat = 0.0 {
        didSet {
            makeTombolaSegments() // we have to redraw new points
        }
    }

    @Published var scale: CGFloat = 0.75 {
        didSet {
            tombolaSegments.forEach {
                $0.xScale = scale
                $0.yScale = scale
            }
        }
    }
    
    @Published var numberOfSides: CGFloat = 6.0 {
        didSet {
            makeTombolaSegments()
        }
    }
        
    private let motionManager = CMMotionManager()
    
    @Published var noteDots: [NoteDot] = []
    
    private var tombolaSegments: [SKShapeNode] = []

    private let midiManager = ObservableMIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    private let midiHelper = MIDIHelper()
    
    @Published var spawnPosition: CGPoint = .zero

    override init() {
        super.init(size: .zero)

        scaleMode = .aspectFit
        backgroundColor = .black
        
        physicsWorld.contactDelegate = self
        physicsWorld.speed = 2.0
        setGravity(gravity)
        
        midiHelper.setup(midiManager: midiManager)
        
        midiHelper.didReceiveMIDIEvent = { [weak self] midiEvent in
            DispatchQueue.main.sync {
                switch midiEvent {
                case .noteOn(let noteOn):
                    self?.keyPress = Int(noteOn.note.number)
                case .cc(let cc):
                    self?.receiveMidiCC(cc)
                default:
                    break
                }
            }
        }
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        motionManager.startAccelerometerUpdates()

        view.backgroundColor = backgroundColor
        view.ignoresSiblingOrder = true

        physicsBody?.categoryBitMask = PhysicsCategory.worldBoundary.bitMask
        physicsBody?.contactTestBitMask = PhysicsCategory.dot.bitMask
        physicsBody = SKPhysicsBody(edgeLoopFrom: view.frame.insetBy(dx: -6.0, dy: -6.0)) // dot radius minus 1

        makeTombolaSegments()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ currentTime: TimeInterval) {
        if previousTime == .zero {
            previousTime = currentTime
        }
        
        r += (rotationSpeed - 5) * 0.01 * -1
        tombolaSegments.forEach {
            $0.zRotation = r
        }

        // This allows us to 'quantize' our note firing events
        // Most importantly, it will concatenate note firing events that happen very close to eachother
        // which may produce unpleasent sounding results
        if previousTime + noteFiringTimeWindow < currentTime {
            fireMidiEvents()
            noteCollection = []
            previousTime = currentTime
        }
        
        if isMotionEnabled, let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 2.0,
                                            dy: accelerometerData.acceleration.y * 2.0)
        }

        super.update(currentTime)
    }
    
    private func fireMidiEvents() {
        noteCollection
            .forEach { [weak self] note in
                self?.midiHelper.sendNoteOn(UInt7(note))
            }
    }
    
    private func receiveMidiCC(_ cc: MIDIEvent.CC) {
        let value = Double(cc.value.midi2Value)
        switch cc.controller.number {
        case 13: // Gravity
            let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 0.1, newMax: 1.5)
            gravity = normalizedValue
        case 14: // Mass
            let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 0.0, newMax: 100.0)
            mass = normalizedValue
        case 15: // Scale
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.2, newMax: 2.0)
            scale = normalizedValue
        case 16: // Torquex
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 10.0)
            rotationSpeed = normalizedValue
        case 17: // Spread
            let normalizedValue = normalize(value: value, min: 0.0, max: 4294967296, newMin: 0.0, newMax: 180.0)
            segmentOffset = normalizedValue
        case 18: // Vertices
            let normalizedValue = normalize(value: value, min: 0.0, max: 127.0, newMin: 2.0, newMax: 13.0)
            numberOfSides = normalizedValue
        default:
            break
        }
    }
}

private extension GameScene {

    func makeNoteDot(_ noteValue: Int) {
        let noteDot = NoteDot(radius: 5.0, noteValue: noteValue, mass: mass)
        noteDot.position = CGPoint(x: view?.frame.midX ?? 0.0, y: view?.frame.midY ?? 0.0)
        noteDots.append(noteDot)
        addChild(noteDot)
    }
    
    func makeTombolaSegments() {
        self.tombolaSegments.forEach {
            $0.removeFromParent()
        }
        self.tombolaSegments = []
        let numberOfSides = Int(self.numberOfSides)
        let viewFrame = view?.frame ?? .zero
        let tombolaSize = viewFrame.size.width * 0.5
        
        let points = calculatePolygonCoordinates(numberOfSides)
            .map { CGPoint(x: $0.0 * tombolaSize, y: $0.1 * tombolaSize) }
                
        var lookaheadIndex = 1
        for point in points {
            if lookaheadIndex == points.count {
                lookaheadIndex = 0
            }
            let path = CGMutablePath()
            let rotatedPoints = rotatePoints(point1: point, point2: points[lookaheadIndex],
                                             angle: degreesToRadians(degrees: segmentOffset))
            path.move(to: rotatedPoints.0)
            path.addLine(to: rotatedPoints.1)
            let segmentNode = SKShapeNode(path: path)
            segmentNode.lineWidth = 3.0
            segmentNode.strokeColor = .orange
            segmentNode.physicsBody = SKPhysicsBody(edgeFrom: rotatedPoints.0, to: rotatedPoints.1)
            segmentNode.physicsBody?.affectedByGravity = false
            segmentNode.physicsBody?.pinned = true
            segmentNode.physicsBody?.mass = 1.0
            segmentNode.physicsBody?.density = 1.0
            segmentNode.physicsBody?.restitution = 1.0
            segmentNode.physicsBody?.allowsRotation = true
            segmentNode.physicsBody?.categoryBitMask = PhysicsCategory.tombola.bitMask
            segmentNode.physicsBody?.collisionBitMask = PhysicsCategory.dot.bitMask
            segmentNode.physicsBody?.contactTestBitMask = PhysicsCategory.dot.bitMask
            segmentNode.physicsBody?.usesPreciseCollisionDetection = true
            segmentNode.position = CGPoint(x: view?.frame.midX ?? .zero, y: view?.frame.midY ?? .zero)
            segmentNode.xScale = scale
            segmentNode.yScale = scale
            self.tombolaSegments.append(segmentNode)
            addChild(segmentNode)
            lookaheadIndex += 1
        }
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
//        if contact.collisionImpulse > 500 {
            // Do something for high impact
//        }

        // This isn't correct, but it works.
        let dotBody = contact.bodyA.categoryBitMask > contact.bodyB.categoryBitMask ? contact.bodyA : contact.bodyB
        
        // This is working, but doesn't make sense. dotBody isn't really the dot
        switch dotBody.categoryOfContact() {
        case .tombola:
            guard contact.collisionImpulse > 1.0 else { return }
            if let noteDotNode = contact.bodyB.node as? NoteDot {
                noteCollection.insert(noteDotNode.noteValue)
//                let freq = noteNumberToFrequency(noteDotNode.noteValue)
//                let dur = cycleDurationInMilliseconds(forFrequency: freq)
//                playPureTone(frequencyInHz: freq, amplitude: 1.0, durationInMillis: dur * 30.0, completion: { })
            }
        // This is supposed to be case .worldBoundary: but this contact stuff isn't figured out properly
        default:
            if let otherBody = contact.bodyB.node as? NoteDot {
                noteDots
                    .removeFirst(where: { $0.uuid == otherBody.uuid })?
                    .removeFromParent()
            }
        }
    }
}

private func noteNumberToFrequency(_ noteNumber: Int) -> Double {
    pow(2.0, Double(noteNumber - 49) / 12.0) * 440.0
}

func cycleDurationInMilliseconds(forFrequency frequency: Double) -> Double {
    1.0 / frequency * 1000.0
}

enum PhysicsCategory: CaseIterable {
    case dot, tombola, worldBoundary

    var bitMask: UInt32 {
        switch self {
        case .dot:
            0x1 << 0
        case .tombola:
            0x1 << 1
        case .worldBoundary:
            0x1 << 2
        }
    }
}

extension SKPhysicsBody {
    
    func categoryOfContact() -> PhysicsCategory? {
        PhysicsCategory.allCases.first { categoryBitMask & $0.bitMask != 0 }
    }
}

import SwiftUI

#Preview {
    ContentView()
}


//
//
//  Swift Pure Tone Generation
//
/*
Copyright (c) 2021 Lee Barney
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation the
 rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the Software
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation
import AVFoundation

func playPureTone(frequencyInHz: Double, amplitude: Float, durationInMillis: Double, completion: @escaping ()->Void) {
    //Use a semaphore to block until the tone completes playing
    let semaphore = DispatchSemaphore(value: 1)
    //Run async in the background so as not to block the current thread
    DispatchQueue.global().async {
        //Build the player and its engine
        let audioPlayer = AVAudioPlayerNode()
        let audioEngine = AVAudioEngine()
        semaphore.wait()//Claim the semphore for blocking
        audioEngine.attach(audioPlayer)
        let mixer = audioEngine.mainMixerNode
        let sampleRateHz = Float(mixer.outputFormat(forBus: 0).sampleRate)
        
        guard let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: Double(sampleRateHz), channels: AVAudioChannelCount(1), interleaved: false) else {
            return
        }
        // Connect the audio engine to the audio player
        audioEngine.connect(audioPlayer, to: mixer, format: format)
        
        
        let numberOfSamples = AVAudioFrameCount((Float(durationInMillis) / 1000 * sampleRateHz))
        //create the appropriatly sized buffer
        guard let buffer  = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: numberOfSamples) else {
            return
        }
        buffer.frameLength = numberOfSamples
        //get a pointer to the buffer of floats
        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(format.channelCount))
        let floats = UnsafeMutableBufferPointer<Float>(start: channels[0], count: Int(numberOfSamples))
        //calculate the angular frequency
        let angularFrequency = Float(frequencyInHz * 2) * .pi
        // Generate and store the sequential samples representing the sine wave of the tone
        for i in 0 ..< Int(numberOfSamples) {
            let waveComponent = sinf(Float(i) * angularFrequency / sampleRateHz)
            floats[i] = waveComponent * amplitude
        }
        do {
            try audioEngine.start()
        }
        catch{
            print("Error: Engine start failure")
            return
        }

        // Play the pure tone represented by the buffer
        audioPlayer.play()
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts){
            DispatchQueue.main.async {
                completion()
                semaphore.signal()//Release one claim of the semiphore
            }
        }
        semaphore.wait()//Wait for the semiphore so the function doesn't end before the playing of the tone completes
        semaphore.signal()//Release the other claim of the semiphore
    }
}
