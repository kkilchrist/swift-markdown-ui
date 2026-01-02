#if !os(tvOS)
  import SwiftUI
  import XCTest

  @testable import MarkdownUI

  final class FontPropertiesTests: XCTestCase {
    // Helper to compare fonts by their string description since SwiftUI Font
    // doesn't implement meaningful equality (two identical fonts may not be ==)
    private func assertFontsEqual(_ expected: Font, _ actual: Font, file: StaticString = #file, line: UInt = #line) {
      XCTAssertEqual(
        String(describing: expected),
        String(describing: actual),
        file: file,
        line: line
      )
    }

    func testFontWithProperties() {
      // given
      var fontProperties = FontProperties()

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(family: .custom("Menlo"))

      // then
      assertFontsEqual(
        Font.custom("Menlo", fixedSize: FontProperties.defaultSize),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(familyVariant: .monospaced)

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default).monospaced(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(capsVariant: .lowercaseSmallCaps)

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default).lowercaseSmallCaps(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(digitVariant: .monospaced)

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default).monospacedDigit(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(style: .italic)

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default).italic(),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(weight: .heavy)

      // then
      assertFontsEqual(
        Font.system(size: FontProperties.defaultSize, design: .default).weight(.heavy),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(size: 42)

      // then
      assertFontsEqual(
        Font.system(size: 42, design: .default),
        Font.withProperties(fontProperties)
      )

      // when
      fontProperties = FontProperties(scale: 1.5)

      // then
      assertFontsEqual(
        Font.system(size: round(FontProperties.defaultSize * 1.5), design: .default),
        Font.withProperties(fontProperties)
      )
    }
  }
#endif
