import Foundation

/// Text direction for layout purposes based on content analysis.
public enum TextDirection: Sendable {
  case leftToRight
  case rightToLeft

  /// Detects text direction using the Unicode Bidirectional Algorithm.
  ///
  /// Finds the first strong directional character in the text to determine direction.
  /// Strong RTL characters include Arabic and Hebrew scripts.
  /// Strong LTR characters include Latin, Greek, Cyrillic, and other left-to-right scripts.
  ///
  /// - Parameter text: The text to analyze.
  /// - Returns: The detected text direction, defaulting to `.leftToRight` if no strong character is found.
  public static func detect(from text: String) -> TextDirection {
    for scalar in text.unicodeScalars {
      if scalar.isStrongRTL {
        return .rightToLeft
      }
      if scalar.isStrongLTR {
        return .leftToRight
      }
    }
    // Default to LTR if no strong directional character found
    return .leftToRight
  }
}

extension Unicode.Scalar {
  /// Returns `true` if this scalar is a strong right-to-left character.
  ///
  /// Covers Arabic and Hebrew script ranges per Unicode Bidirectional Algorithm.
  fileprivate var isStrongRTL: Bool {
    let value = self.value
    return
      // Hebrew: U+0590-U+05FF, Presentation Forms U+FB1D-U+FB4F
      (0x0590...0x05FF).contains(value) ||
      (0xFB1D...0xFB4F).contains(value) ||
      // Arabic: U+0600-U+06FF
      (0x0600...0x06FF).contains(value) ||
      // Syriac: U+0700-U+074F
      (0x0700...0x074F).contains(value) ||
      // Arabic Supplement: U+0750-U+077F
      (0x0750...0x077F).contains(value) ||
      // Thaana: U+0780-U+07BF
      (0x0780...0x07BF).contains(value) ||
      // NKo: U+07C0-U+07FF
      (0x07C0...0x07FF).contains(value) ||
      // Samaritan: U+0800-U+083F
      (0x0800...0x083F).contains(value) ||
      // Mandaic: U+0840-U+085F
      (0x0840...0x085F).contains(value) ||
      // Arabic Extended-A: U+08A0-U+08FF
      (0x08A0...0x08FF).contains(value) ||
      // Arabic Presentation Forms-A: U+FB50-U+FDFF
      (0xFB50...0xFDFF).contains(value) ||
      // Arabic Presentation Forms-B: U+FE70-U+FEFF
      (0xFE70...0xFEFF).contains(value)
  }

  /// Returns `true` if this scalar is a strong left-to-right character.
  ///
  /// Covers Latin, Greek, Cyrillic, and other LTR scripts.
  fileprivate var isStrongLTR: Bool {
    let category = self.properties.generalCategory
    switch category {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter:
      // It's a letter, but not in RTL ranges (checked above first)
      return !self.isStrongRTL
    default:
      return false
    }
  }
}
