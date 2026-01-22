@testable import MarkdownUI
import MarkdownUICore
import SwiftUI
import XCTest

final class TextStyleBuilderTests: XCTestCase {
  // MARK: - CriticMarkup Style Tests

  func testCriticAdditionStyleAttributes() {
    // given
    let style = CriticAdditionStyle()

    // when
    var attributes = AttributeContainer()
    style._collectAttributes(in: &attributes)

    // then
    XCTAssertEqual(attributes.foregroundColor, Color.green)
    XCTAssertEqual(attributes.underlineStyle, Text.LineStyle.single)
  }

  func testCriticDeletionStyleAttributes() {
    // given
    let style = CriticDeletionStyle()

    // when
    var attributes = AttributeContainer()
    style._collectAttributes(in: &attributes)

    // then
    XCTAssertEqual(attributes.foregroundColor, Color.red)
    XCTAssertEqual(attributes.strikethroughStyle, Text.LineStyle.single)
  }

  func testCriticSubstitutionAttributedStringRendering() {
    // given: A substitution node with old and new content
    let substitution = InlineNode.criticSubstitution(
      oldContent: [.text("old text")],
      newContent: [.text("new text")]
    )

    let textStyles = InlineTextStyles(
      code: EmptyTextStyle(),
      emphasis: EmptyTextStyle(),
      strong: EmptyTextStyle(),
      strikethrough: EmptyTextStyle(),
      highlight: EmptyTextStyle(),
      link: EmptyTextStyle(),
      softBreak: .default,
      criticAddition: CriticAdditionStyle(),
      criticDeletion: CriticDeletionStyle(),
      criticSubstitutionOld: CriticDeletionStyle(),
      criticSubstitutionNew: CriticAdditionStyle(),
      criticComment: CriticCommentStyle(),
      criticHighlight: BackgroundColor(.yellow.opacity(0.4))
    )

    // when
    let attributedString = substitution.renderAttributedString(
      baseURL: nil,
      textStyles: textStyles,
      softBreakMode: .space,
      attributes: AttributeContainer()
    )

    // then: Verify the attributed string has correct runs with correct colors
    let runs = Array(attributedString.runs)
    XCTAssertEqual(runs.count, 2, "Should have 2 runs: old and new content")

    // First run should be old content with red foreground and strikethrough
    let oldRun = runs[0]
    XCTAssertEqual(String(attributedString[oldRun.range].characters), "old text")
    XCTAssertEqual(oldRun.foregroundColor, Color.red, "Old content should be red")
    XCTAssertEqual(oldRun.strikethroughStyle, Text.LineStyle.single, "Old content should have strikethrough")

    // Second run should be new content with green foreground and underline
    let newRun = runs[1]
    XCTAssertEqual(String(attributedString[newRun.range].characters), "new text")
    XCTAssertEqual(newRun.foregroundColor, Color.green, "New content should be green")
    XCTAssertEqual(newRun.underlineStyle, Text.LineStyle.single, "New content should have underline")
  }

  func testBuildEmpty() {
    // given
    @TextStyleBuilder func build() -> some TextStyle {}
    let textStyle = build()

    // when
    var attributes = AttributeContainer()
    textStyle._collectAttributes(in: &attributes)

    // then
    XCTAssertEqual(AttributeContainer(), attributes)
  }

  func testBuildOne() {
    // given
    @TextStyleBuilder func build() -> some TextStyle {
      ForegroundColor(.primary)
    }
    let textStyle = build()

    // when
    var attributes = AttributeContainer()
    textStyle._collectAttributes(in: &attributes)

    // then
    XCTAssertEqual(AttributeContainer().foregroundColor(.primary), attributes)
  }

  func testBuildMany() {
    // given
    @TextStyleBuilder func build() -> some TextStyle {
      ForegroundColor(.primary)
      BackgroundColor(.cyan)
      UnderlineStyle(.single)
    }
    let textStyle = build()

    // when
    var attributes = AttributeContainer()
    textStyle._collectAttributes(in: &attributes)

    // then
    XCTAssertEqual(
      AttributeContainer()
        .foregroundColor(.primary)
        .backgroundColor(.cyan)
        .underlineStyle(.single),
      attributes
    )
  }

  func testBuildOptional() {
    // given
    @TextStyleBuilder func makeTextStyle(_ condition: Bool) -> some TextStyle {
      ForegroundColor(.primary)
      if condition {
        BackgroundColor(.cyan)
      }
    }
    let textStyle1 = makeTextStyle(true)
    let textStyle2 = makeTextStyle(false)

    // when
    var attributes1 = AttributeContainer()
    textStyle1._collectAttributes(in: &attributes1)
    var attributes2 = AttributeContainer()
    textStyle2._collectAttributes(in: &attributes2)

    // then
    XCTAssertEqual(
      AttributeContainer()
        .foregroundColor(.primary)
        .backgroundColor(.cyan),
      attributes1
    )
    XCTAssertEqual(
      AttributeContainer()
        .foregroundColor(.primary),
      attributes2
    )
  }

  func testBuildEither() {
    // given
    @TextStyleBuilder func makeTextStyle(_ condition: Bool) -> some TextStyle {
      ForegroundColor(.primary)
      if condition {
        BackgroundColor(.cyan)
      } else {
        UnderlineStyle(.single)
      }
    }
    let textStyle1 = makeTextStyle(true)
    let textStyle2 = makeTextStyle(false)

    // when
    var attributes1 = AttributeContainer()
    textStyle1._collectAttributes(in: &attributes1)
    var attributes2 = AttributeContainer()
    textStyle2._collectAttributes(in: &attributes2)

    // then
    XCTAssertEqual(
      AttributeContainer()
        .foregroundColor(.primary)
        .backgroundColor(.cyan),
      attributes1
    )
    XCTAssertEqual(
      AttributeContainer()
        .foregroundColor(.primary)
        .underlineStyle(.single),
      attributes2
    )
  }
}
