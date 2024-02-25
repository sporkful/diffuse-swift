import Foundation

public struct MaterializedDiff<Element: Hashable> {

  public enum Change {
    case none(element: Element, oldOffset: Int, newOffset: Int)
    case insert(element: Element, newOffset: Int)
    case remove(element: Element, oldOffset: Int)
  }

  private(set) var contents: [Change]

  init(canonicalDifferenceWithMoves: CollectionDifference<Element>) {

  }

}

