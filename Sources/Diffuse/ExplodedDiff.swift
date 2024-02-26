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

    // Since `unappliedRemovalCounter` is intended to be indexed into by
    // `(insertion._offset - numUnappliedInsertions)`, it is in the coordinate
    // space where removals were actually applied (but insertions were not),
    // NOT the coordinate space wrt `base`.
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
      // The `+ 1` here helps us stay in the correct coordinate space.
      previousOffset = removal._offset + 1
    }
    // Note the extra `+ 1` element below is to support off-the-end insertions,
    // i.e. insertions that ultimately have an "appending" effect.
    unappliedRemovalCounter.append(
      contentsOf: Array(
        repeating: canonicalDiff.removals.count,
        count: (base.count - canonicalDiff.removals.count) - unappliedRemovalCounter.count + 1
      )
    )
    guard unappliedRemovalCounter.count == base.count - canonicalDiff.removals.count + 1 else {
      throw DiffuseError.DEV
    }

    // hunkEndOffset[baseOffset] = endOffset of hunk (e.g. removed subrange) containing baseOffset.
    var hunkEndOffset: [Int] = Array(0..<(base.count + 1))
    if canonicalDiff.removals.count >= 2 {
      var currentHunkStartOffset: Int = canonicalDiff.removals.first!._offset
      var currentHunkEndOffset: Int = currentHunkStartOffset + 1
      for removal in canonicalDiff.removals[1...] {
        if removal._offset == currentHunkEndOffset {
          // current hunk continues
          currentHunkEndOffset += 1
        } else {
          // current hunk ended (before current removal)
          hunkEndOffset.replaceSubrange(
            currentHunkStartOffset..<currentHunkEndOffset,
            with: Array(
              repeating: currentHunkEndOffset,
              count: currentHunkEndOffset - currentHunkStartOffset
            )
          )
          // start new hunk for current removal
          currentHunkStartOffset = removal._offset
          currentHunkEndOffset = currentHunkStartOffset + 1
        }
      }
      // close last hunk
      hunkEndOffset.replaceSubrange(
        currentHunkStartOffset..<currentHunkEndOffset,
        with: Array(
          repeating: currentHunkEndOffset,
          count: currentHunkEndOffset - currentHunkStartOffset
        )
      )
    }
    guard hunkEndOffset.count == base.count + 1 else {
      throw DiffuseError.DEV
    }

    var insertions: [Int: [InsertedElement]] = [:]
    for (numUnappliedInsertions, insertion) in canonicalDiff.insertions.enumerated() {
      let offsetWrtBase = hunkEndOffset[
        insertion._offset - numUnappliedInsertions
          + unappliedRemovalCounter[(insertion._offset - numUnappliedInsertions)]
      ]

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
