import XCTest
@testable import Diffuse

final class CollectionDifferenceExtTests: XCTestCase {

  func testInferringMultipleMovesEffect(
    old: [String],
    new: [String],
    withLogging: Bool = false
  ) throws {
    var log: [String] = []
    if withLogging {
      log.append("=== START ITERATION ===")
      log.append("old: \(old)")
      log.append("new: \(new)")
      log.append("*** START OPERATIONS ***")
    }

    var result = old
    for change in try new.difference(from: old).inferringMultipleMoves() {
      switch change {
      case .remove(offset: let offset, element: let element, associatedWith: _):
        let removedElement = result.remove(at: offset)
        XCTAssertEqual(removedElement, element)
      case .insert(offset: let offset, element: let element, associatedWith: _):
        result.insert(element, at: offset)
      }

      if withLogging {
        log.append(String(describing: change))
      }
    }

    if withLogging {
      log.append("*** END OPERATIONS ***")
      log.append("=== END ITERATION ===")
      print(log.map({ "\t\($0)" }).joined(separator: "\n"))
    }

    XCTAssertEqual(new, result)
  }

  func testBasic1() throws {
    let old = ["A", "A", "B", "B", "C", "C"]
    let new = ["B", "B", "C", "C", "A", "A"]
    try testInferringMultipleMovesEffect(old: old, new: new, withLogging: true)
  }

  func testBasic2() throws {
    let old = ["A", "A", "B", "B", "C", "C", "D", "D"]
    let new = ["B", "A", "C", "C", "C", "A", "A", "B", "D"]
    try testInferringMultipleMovesEffect(old: old, new: new, withLogging: true)
  }

  func testFuzzEdited(
    numTests: UInt,
    generator: RandomStringGenerator,
    possibleListLengths: Range<UInt>,
    possibleNumEdits: Range<UInt>,
    withLogging: Bool = false
  ) throws {
    for _ in 0..<numTests {
      let old = generator.randomList(possibleLengths: possibleListLengths)
      let new = randomlyEdited(original: old, possibleNumEdits: possibleNumEdits, generator: generator)
      try testInferringMultipleMovesEffect(old: old, new: new, withLogging: withLogging)
    }
  }

  func testFuzzEditedSmall() throws {
    try testFuzzEdited(
      numTests: 100,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20),
      possibleListLengths: 0..<20,
      possibleNumEdits: 0..<20,
      withLogging: true
    )
  }

  func testFuzzEditedDense() throws {
    try testFuzzEdited(
      numTests: 10000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20),
      possibleListLengths: 0..<200,
      possibleNumEdits: 0..<200
    )
  }

  func testFuzzEditedSparse() throws {
    try testFuzzEdited(
      numTests: 10000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 2000),
      possibleListLengths: 0..<200,
      possibleNumEdits: 0..<200
    )
  }

  func testFuzzEditedXL() throws {
    try testFuzzEdited(
      numTests: 100,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20000),
      possibleListLengths: 10000..<20000,
      possibleNumEdits: 1000..<2000
    )
  }

}
