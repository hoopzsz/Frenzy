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
