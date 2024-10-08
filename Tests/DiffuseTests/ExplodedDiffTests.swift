import XCTest
@testable import Diffuse

final class ExplodedDiffTests: XCTestCase {

  func testExplodedDiffEffect(
    old: [String],
    new: [String]
  ) throws {
    let explodedDiff = try ExplodedDiff(
      canonicalDiff: new.difference(from: old).inferringMultipleMoves(),
      from: old
    )
    var result: [String] = []
    for (offsetWrtBase, baseElement) in explodedDiff.base.enumerated() {
      result.append(contentsOf: explodedDiff.insertions[offsetWrtBase].map { $0.element })
      switch baseElement.change {
      case .none:
        result.append(baseElement.element)
      case .removed(associatedWith: let associatedWith):
        continue
      }
    }
    if let appendedElements = explodedDiff.insertions.last {
      result.append(contentsOf: appendedElements.map { $0.element })
    }
    XCTAssertEqual(new, result)
  }

  func visualizeExplodedDiff(
    old: [String],
    new: [String]
  ) throws {
    var log: [String] = []
    log.append("=== START ITERATION ===")
    log.append("old: \(old)")
    log.append("new: \(new)")
    log.append("*** START VISUAL ***")

    let explodedDiff = try ExplodedDiff(
      canonicalDiff: new.difference(from: old).inferringMultipleMoves(),
      from: old
    )
    for (offsetWrtBase, baseElement) in explodedDiff.base.enumerated() {
      log.append(
        contentsOf: explodedDiff.insertions[offsetWrtBase].map {
          "+  \($0.element) \(String(describing: $0.associatedWith))"
        }
      )
      switch baseElement.change {
      case .none:
        log.append("   \(baseElement.element)")
      case .removed(associatedWith: let associatedWith):
        log.append("-  \(baseElement.element) \(String(describing: associatedWith))")
      }
    }
    if let appendedElements = explodedDiff.insertions.last {
      log.append(
        contentsOf: appendedElements.map {
          "+  \($0.element) \(String(describing: $0.associatedWith))"
        }
      )
    }

    log.append("*** END VISUAL ***")
    log.append("=== END ITERATION ===")
    print(log.map({ "\t\($0)" }).joined(separator: "\n"))
  }

  func testBasic00() throws {
    let old = ["A", "B", "C"]
    let new = ["A", "B", "C", "X", "Y", "Z"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic01() throws {
    let old = ["A", "B", "C"]
    let new = ["X", "Y", "Z", "A", "B", "C"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic02() throws {
    let old = ["A", "B", "C"]
    let new = ["A", "X", "B", "Y", "C", "Z"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic03() throws {
    let old = ["A", "B", "C"]
    let new = ["X", "A", "Y", "B", "Z", "C"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic04() throws {
    let old = ["A", "B", "C"]
    let new = ["A", "Y", "C"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic05() throws {
    let old = ["A", "B", "C"]
    let new = ["A", "X", "Y", "Z", "C"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic06() throws {
    let old = ["A", "B", "C"]
    let new = ["A", "X", "Y", "Z"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic07() throws {
    let old = ["A", "B", "C"]
    let new = ["X", "Y", "Z"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic08() throws {
    let old = ["A", "B", "C"]
    let new = ["X", "Y", "Z", "A"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic09() throws {
    let old = ["A", "B", "C"]
    let new = ["B", "X", "Y", "Z", "A"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
  }

  func testBasic11() throws {
    let old = ["A", "B", "C", "D", "E", "F", "G"]
    let new = ["B", "C", "X", "Y", "Z", "F", "G"]
    try visualizeExplodedDiff(old: old, new: new)
    try testExplodedDiffEffect(old: old, new: new)
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
//      try visualizeExplodedDiff(old: old, new: new)
      try testExplodedDiffEffect(old: old, new: new)
    }
  }

  func testFuzzEditedSmall() throws {
    try testFuzzEdited(
      numTests: 100000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20),
      possibleListLengths: 0..<20,
      possibleNumEdits: 0..<200,
      withLogging: true
    )
  }

  func testFuzzEditedDense() throws {
    try testFuzzEdited(
      numTests: 100000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20),
      possibleListLengths: 0..<200,
      possibleNumEdits: 0..<200
    )
  }

  func testFuzzEditedSparse() throws {
    try testFuzzEdited(
      numTests: 100000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 2000),
      possibleListLengths: 0..<200,
      possibleNumEdits: 0..<200
    )
  }

  func testFuzzEditedXL() throws {
    try testFuzzEdited(
      numTests: 1000,
      generator: RandomStringGenerator(alphabet: .uInt16, numPossibleValues: 20000),
      possibleListLengths: 10000..<20000,
      possibleNumEdits: 1000..<2000
    )
  }

}
