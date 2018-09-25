//
//  OrderedDictionary.swift
//  JSON
//
//  Created by Mikael Brockman on 2018-09-25.
//

import Foundation

public class OrderedDictionary {
  var entries: [(String, JSON)] = []
  
  init(_ entries: [(String, JSON)]) {
    self.entries = entries
  }
  
  subscript(index: String) -> JSON? {
    get {
      if let (_, o) = entries.first(where: { $0.0 == index }) {
        return o
      } else {
        return nil
      }
    }
    
    set(newValue) {
      if let i = entries.firstIndex(where: { $0.0 == index }) {
        if let newValue = newValue {
          entries[i] = (index, newValue)
        } else {
          entries.remove(at: i)
        }
      } else {
        if let newValue = newValue {
          entries.append((index, newValue))
        }
      }
    }
  }
}

extension OrderedDictionary: Equatable {
  public static func == (lhs: OrderedDictionary, rhs: OrderedDictionary) -> Bool {
    if lhs.entries.count != rhs.entries.count { return false }
    for i in 0..<lhs.entries.count {
      if lhs.entries[i].0 != rhs.entries[i].0 { return false }
      if lhs.entries[i].1 != rhs.entries[i].1 { return false }
    }
    return true
  }
}
