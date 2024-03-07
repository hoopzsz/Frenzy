//
//  Set+Extensions.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-03-06.
//

import Foundation

extension Set {

    /// Adds an element to the Set if ithe Set does not already have it. Otherwise removes the value from the Set.
    mutating func toggle(_ element: Set.Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}
