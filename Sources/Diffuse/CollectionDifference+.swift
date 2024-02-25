extension CollectionDifference.Change {
  internal var _offset: Int {
    get {
      switch self {
      case .insert(offset: let o, element: _, associatedWith: _):
        return o
      case .remove(offset: let o, element: _, associatedWith: _):
        return o
      }
    }
  }
  internal var _element: ChangeElement {
    get {
      switch self {
      case .insert(offset: _, element: let e, associatedWith: _):
        return e
      case .remove(offset: _, element: let e, associatedWith: _):
        return e
      }
    }
  }
  internal var _associatedOffset: Int? {
    get {
      switch self {
      case .insert(offset: _, element: _, associatedWith: let o):
        return o
      case .remove(offset: _, element: _, associatedWith: let o):
        return o
      }
    }
  }
}

extension CollectionDifference where ChangeElement: Hashable {

  func inferringMultipleMoves() throws -> CollectionDifference<ChangeElement> {
    var unmatchedRemovals: [ChangeElement:[Int]] = Dictionary(
      uniqueKeysWithValues: Set(self.removals.map { $0._element }).map { ($0, []) }
    )
    for removal in self.removals.reversed() {
      unmatchedRemovals[removal._element]!.append(removal._offset)
    }

    var changes: [Change] = []
    for insertion in self.insertions {
      if let matchedRemovalOffset = unmatchedRemovals[insertion._element]?.popLast() {
        changes.append(
          .insert(
            offset: insertion._offset,
            element: insertion._element,
            associatedWith: matchedRemovalOffset
          )
        )
        changes.append(
          .remove(
            offset: matchedRemovalOffset,
            element: insertion._element,
            associatedWith: insertion._offset
          )
        )
      } else {
        changes.append(
          .insert(
            offset: insertion._offset,
            element: insertion._element,
            associatedWith: nil
          )
        )
      }
    }

    changes.append(
      contentsOf: unmatchedRemovals.flatMap { (element, offsets) in
        offsets.map { (offset) in
          Change.remove(offset: offset, element: element, associatedWith: nil)
        }
      }
    )

    guard let diff = CollectionDifference(changes) else {
      throw DiffuseError.validation
    }

    return diff
  }

}
