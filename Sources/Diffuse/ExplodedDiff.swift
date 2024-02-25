import Foundation
import SwiftUI

public struct ExplodedDiff<Element: Hashable> {
  public struct BaseElement {
    let element: Element
    var change: BaseChange

    public enum BaseChange: Equatable {
      case none
      case removed(associatedWith: Int?) // wrt canonicalDiff::new
    }
  }

  public struct InsertedElement {
    let element: Element
    let associatedWith: Int? // wrt canonicalDiff::original (note equivalence wrt self.base)
  }

  let base: [BaseElement]
  let insertions: [Int: [InsertedElement]] // key = offsetWrtBase

  // TODO: clarify assumptions about diff generation, e.g. being generated from an array
  // since the current impl is not particularly conscious of distinctions between index vs offset.
  init(canonicalDiff: CollectionDifference<Element>, from original: [Element]) throws {
    var base: [BaseElement]
    base = original.map { element in BaseElement(element: element, change: .none) }

    // unappliedRemovalCounter[baseOffset] = numUnappliedRemovals affecting insert at baseOffset
    var unappliedRemovalCounter: [Int] = []
    var previousOffset = 0
    for (numUnappliedRemovals, removal) in canonicalDiff.removals.enumerated() {
      guard base[removal._offset].element == removal._element else {
        throw DiffuseError.validation
      }
      base[removal._offset].change = .removed(associatedWith: nil)

      unappliedRemovalCounter.append(
        contentsOf: Array(
          repeating: numUnappliedRemovals,
          count: removal._offset - previousOffset
        )
      )
      previousOffset = removal._offset
    }
    // +1 for insertions that have an "append" effect
    unappliedRemovalCounter.append(
      contentsOf: Array(
        repeating: canonicalDiff.removals.count,
        count: base.count - previousOffset + 1
      )
    )
    guard unappliedRemovalCounter.count == base.count + 1 else {
      throw DiffuseError.DEV
    }

    var insertions: [Int: [InsertedElement]] = [:]

    for (numUnappliedInsertions, insertion) in canonicalDiff.insertions.enumerated() {
      let offsetWrtBase = insertion._offset - numUnappliedInsertions
        + unappliedRemovalCounter[(insertion._offset - numUnappliedInsertions)]

      if insertions[offsetWrtBase] == nil {
        insertions[offsetWrtBase] = []
      }
      insertions[offsetWrtBase]!.append(
        InsertedElement(
          element: insertion._element,
          associatedWith: insertion._associatedOffset
        )
      )

      if let associatedOffset = insertion._associatedOffset {
        guard base[associatedOffset].change == .removed(associatedWith: nil) else {
          throw DiffuseError.DEV
        }
        base[associatedOffset].change = .removed(associatedWith: insertion._offset)
      }
    }

    self.base = base
    self.insertions = insertions
  }
}
