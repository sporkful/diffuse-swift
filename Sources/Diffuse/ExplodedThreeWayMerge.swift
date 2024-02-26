import Foundation

public struct ExplodedThreeWayMerge<Element: Hashable> {
  struct CommonBaseElement {
    let element: Element
    let localChange: ExplodedDiff<Element>.BaseElement.BaseChange
    let remoteChange: ExplodedDiff<Element>.BaseElement.BaseChange
    let isConflicting: Bool

    init(
      element: Element,
      localChange: ExplodedDiff<Element>.BaseElement.BaseChange,
      remoteChange: ExplodedDiff<Element>.BaseElement.BaseChange
    ) {
      self.element = element
      self.localChange = localChange
      self.remoteChange = remoteChange
      self.isConflicting = (localChange != remoteChange)
    }
  }

  // TODO: rethink semantics around isConflicting
  // Currently, `isConflicting` is a conservative marker. In particular, even if the two insertion
  // hunks have the same values in the same order, `isConflicting` may still be set to true, e.g. in
  // the case that at least one value has conflicting "sources" (e.g. was part of a move locally but
  // was a pure insertion remotely).
  struct CommonInsertionHunk {
    let localInsertionHunk: ExplodedDiff<Element>.InsertionHunk
    let remoteInsertionHunk: ExplodedDiff<Element>.InsertionHunk
    let isConflicting: Bool

    init(
      localInsertionHunk: ExplodedDiff<Element>.InsertionHunk,
      remoteInsertionHunk: ExplodedDiff<Element>.InsertionHunk
    ) {
      self.localInsertionHunk = localInsertionHunk
      self.remoteInsertionHunk = remoteInsertionHunk
      self.isConflicting = (localInsertionHunk != remoteInsertionHunk)
    }
  }

  let base: [CommonBaseElement]
  let insertions: [CommonInsertionHunk] // index = offsetWrtBase

  init(localDiff: ExplodedDiff<Element>, remoteDiff: ExplodedDiff<Element>) throws {
    guard localDiff.base.elementsEqual(remoteDiff.base, by: { $0.element == $1.element }) else {
      throw DiffuseError.validation
    }

    self.base = zip(localDiff.base, remoteDiff.base)
      .map { (localBaseElement, remoteBaseElement) in
        CommonBaseElement(
          element: localBaseElement.element,
          localChange: localBaseElement.change,
          remoteChange: remoteBaseElement.change
        )
      }

    self.insertions = zip(localDiff.insertions, remoteDiff.insertions)
      .map { CommonInsertionHunk(localInsertionHunk: $0, remoteInsertionHunk: $1)}
  }
}
