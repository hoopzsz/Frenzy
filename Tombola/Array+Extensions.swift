//
//  Array+Extensions.swift
//  Tombola
//
//  Created by Daniel Hooper on 2024-02-13.
//

import Foundation

extension Array {
    
    mutating func removeFirst(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        do {
            if let firstIndex = try firstIndex(where: predicate) {
                return self.remove(at: firstIndex)
            } else {
                return nil
            }
        }
        catch {
            throw error
        }
    }
}

//extension Set {
//
//    /// Adds an element to the Set if ithe Set does not already have it. Otherwise removes the value from the Set.
//    mutating func toggle(_ element: Set.Element) {
//        if contains(element) {
//            remove(element)
//        } else {
//            insert(element)
//        }
//    }
//}
