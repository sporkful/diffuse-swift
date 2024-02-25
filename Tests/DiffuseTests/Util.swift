import Diffuse

enum DiffuseTestError: Error {
  case fuzz(detail: String)
}

struct RandomStringGenerator {
  enum Alphabet {
    case uInt16
    case englishLetters

    var maxValue: UInt16 {
      switch self {
      case .uInt16: UInt16.max
      case .englishLetters: 25  // zero-indexed
      }
    }
  }

  let alphabet: Alphabet
  let numPossibleValues: UInt16

  init(alphabet: Alphabet, numPossibleValues: UInt16) throws {
    guard (numPossibleValues - 1) <= alphabet.maxValue else {
      throw DiffuseTestError.fuzz(detail: "RSG init - numPossibleValues out of alphabet's range")
    }

    self.alphabet = alphabet
    self.numPossibleValues = numPossibleValues
  }

  func randomValue() -> String {
    let rawRandomValue = UInt16.random(in: 0..<self.numPossibleValues)
    return switch self.alphabet {
    case .englishLetters:
      String(Character(UnicodeScalar(rawRandomValue + UInt16(("A" as UnicodeScalar).value))!))
    case .uInt16:
      String(rawRandomValue)
    }
  }

  func randomList(possibleLengths: Range<UInt>) -> [String] {
    let listLength = UInt.random(in: possibleLengths)
    return (0..<listLength).map { _ in self.randomValue() }
  }
}

// TODO: allow specifying probability distributions?
func randomlyEdited(
  original: [String],
  possibleNumEdits: Range<UInt>,
  generator: RandomStringGenerator
) -> [String] {
  var result = original
  for _ in 0..<UInt.random(in: possibleNumEdits) {
    switch UInt.random(in: 0..<3) {
    case 0:
      result.insert(
        generator.randomValue(),
        at: Int.random(in: 0...result.count)
      )
    case 1:
      if result.count == 0 {
        continue
      }
      result.remove(at: Int.random(in: 0..<result.count))
    case 2:
      if result.count == 0 {
        continue
      }
      let elementToMove = result.remove(at: Int.random(in: 0..<result.count))
      result.insert(elementToMove, at: Int.random(in: 0...result.count))
    default:
      continue
    }
  }
  return result
}
