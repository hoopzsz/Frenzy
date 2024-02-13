//
//  Math.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import Foundation

func calculatePolygonCoordinates(_ numberOfSides: Int) -> [(Double, Double)] {
    var coordinates = [(Double, Double)]()
    for i in 0..<numberOfSides {
        let angle = 2 * Double.pi * Double(i) / Double(numberOfSides)
        let x = cos(angle)
        let y = sin(angle)
        coordinates.append((x, y))
    }
    return coordinates
}

func degreesToRadians(degrees: Double) -> Double {
    degrees * Double.pi / 180.0
}

// Function to rotate a point by a given angle (in radians) around the origin
func rotatePoint(point: CGPoint, angle: CGFloat) -> CGPoint {
    let rotatedX = point.x * cos(angle) - point.y * sin(angle)
    let rotatedY = point.x * sin(angle) + point.y * cos(angle)
    return CGPoint(x: rotatedX, y: rotatedY)
}

// Function to rotate two points around their center by a given angle (in radians)
func rotatePoints(point1: CGPoint, point2: CGPoint, angle: CGFloat) -> (CGPoint, CGPoint) {
    // Calculate the center point
    let centerX = (point1.x + point2.x) / 2
    let centerY = (point1.y + point2.y) / 2
    let center = CGPoint(x: centerX, y: centerY)
    
    // Translate points to origin
    let translatedPoint1 = CGPoint(x: point1.x - center.x, y: point1.y - center.y)
    let translatedPoint2 = CGPoint(x: point2.x - center.x, y: point2.y - center.y)
    
    // Rotate translated points
    let rotatedTranslatedPoint1 = rotatePoint(point: translatedPoint1, angle: angle)
    let rotatedTranslatedPoint2 = rotatePoint(point: translatedPoint2, angle: angle)
    
    // Translate rotated points back
    let rotatedPoint1 = CGPoint(x: rotatedTranslatedPoint1.x + center.x, y: rotatedTranslatedPoint1.y + center.y)
    let rotatedPoint2 = CGPoint(x: rotatedTranslatedPoint2.x + center.x, y: rotatedTranslatedPoint2.y + center.y)
    
    return (rotatedPoint1, rotatedPoint2)
}

func normalize(value: Double, min: Double, max: Double, newMin: Double, newMax: Double) -> Double {
    let normalizedValue = (value - min) / (max - min)
    let newValue = normalizedValue * (newMax - newMin) + newMin
    return newValue
}

func noteNumberToFrequency(_ noteNumber: Int) -> Double {
    pow(2.0, Double(noteNumber - 49) / 12.0) * 440.0
}

func cycleDurationInMilliseconds(forFrequency frequency: Double) -> Double {
    1.0 / frequency * 1000.0
}
