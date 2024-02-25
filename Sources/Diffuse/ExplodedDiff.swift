import Foundation
import SwiftUI

public struct ExplodedDiff<Element: Hashable> {
  public struct BaseElement {
    let element: Element
    var change: BaseChange

    public enum BaseChange {
      case none
      case removed(associatedWith: Int?)
    }
  }

  public struct InsertedElement {
    let element: Element
    let associatedWith: Int?
  }

  let base: [BaseElement]
  let insertions: [Int: [InsertedElement]] // key = offsetWrtBase

  // TODO: clarify assumptions about diff generation, e.g. being generated from an array
  // since the current impl is not particularly conscious of distinctions between index vs offset.
  init(canonicalDiff: CollectionDifference<Element>, from original: [Element]) throws {
    var base: [BaseElement]
    base = original.map { element in BaseElement(element: element, change: .none) }

    // key = offset
    // value = numUnappliedRemovals affecting offset..<(nextOffset ?? endOffset)
    var unappliedRemovalCounter: [Int: Int] = [:]

    for (numUnappliedRemovals, removal) in canonicalDiff.removals.enumerated() {
      guard base[removal._offset].element == removal._element else {
        throw DiffuseError.validation
      }
      base[removal._offset].change = .removed(associatedWith: nil)

      // + 1 since the un-application of the current removal also affects offset..<nextOffset
      unappliedRemovalCounter[removal._offset] = numUnappliedRemovals + 1
    }

    self.base = base

    var insertions: [Int: [InsertedElement]] = [:]

    for (numUnappliedInsertions, insertion) in canonicalDiff.insertions.enumerated() {
      // TODO: if removals are sparse, may take a long time to search for which range in
      // unappliedRemovalCounter that this insertion belongs to
    }

    self.insertions = insertions
  }
}
