import MarkdownUI
import XCTest

final class SoftBreakStyleTests: XCTestCase {
  // MARK: - SoftBreakStyle Tests

  func testDefaultSoftBreakStyle() {
    // given
    let style = SoftBreakStyle.default

    // then
    XCTAssertNil(style.spacing)
  }

  func testSoftBreakStyleWithSpacing() {
    // given
    let spacing = RelativeSize.em(0.5)
    let style = SoftBreakStyle(spacing: spacing)

    // then
    XCTAssertEqual(spacing, style.spacing)
  }

  func testSoftBreakStyleWithNilSpacing() {
    // given
    let style = SoftBreakStyle(spacing: nil)

    // then
    XCTAssertNil(style.spacing)
  }

  // MARK: - Spacing TextStyle Tests

  func testSpacingWithFixedPoints() {
    // given
    let theme = Theme().softBreak { Spacing(12) }

    // then - verify spacing was set
    XCTAssertNotNil(theme.softBreak.spacing)
  }

  func testSpacingWithRelativeSizeEm() {
    // given
    let theme = Theme().softBreak {
      Spacing(.em(0.5))
    }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.em(0.5), theme.softBreak.spacing)
  }

  func testSpacingWithRelativeSizeRem() {
    // given
    let theme = Theme().softBreak {
      Spacing(.rem(1))
    }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.rem(1), theme.softBreak.spacing)
  }

  // MARK: - RelativeSize Tests

  func testRelativeSizeEmEquality() {
    // given
    let size1 = RelativeSize.em(0.5)
    let size2 = RelativeSize.em(0.5)
    let size3 = RelativeSize.em(1.0)

    // then
    XCTAssertEqual(size1, size2)
    XCTAssertNotEqual(size1, size3)
  }

  func testRelativeSizeRemEquality() {
    // given
    let size1 = RelativeSize.rem(0.5)
    let size2 = RelativeSize.rem(0.5)
    let size3 = RelativeSize.rem(1.0)

    // then
    XCTAssertEqual(size1, size2)
    XCTAssertNotEqual(size1, size3)
  }

  func testRelativeSizeEmVsRemNotEqual() {
    // given
    let emSize = RelativeSize.em(1.0)
    let remSize = RelativeSize.rem(1.0)

    // then - same value but different units should not be equal
    XCTAssertNotEqual(emSize, remSize)
  }

  func testRelativeSizeZero() {
    // given
    let zero = RelativeSize.zero

    // then - zero is defined as rem(0)
    XCTAssertEqual(.rem(0), zero)
  }

  // MARK: - Theme Builder Tests

  func testThemeSoftBreakBuilder() {
    // given
    let theme = Theme()
      .softBreak {
        Spacing(8)
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
  }

  func testThemeSoftBreakBuilderWithRelativeSize() {
    // given
    let theme = Theme()
      .softBreak {
        Spacing(.em(0.5))
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.em(0.5), theme.softBreak.spacing)
  }

  func testThemeDefaultSoftBreakStyle() {
    // given
    let theme = Theme()

    // then
    XCTAssertNil(theme.softBreak.spacing)
  }

  func testThemeSoftBreakChainedWithOtherStyles() {
    // given
    let theme = Theme()
      .code {
        FontFamilyVariant(.monospaced)
      }
      .softBreak {
        Spacing(.em(0.25))
      }
      .emphasis {
        FontStyle(.italic)
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.em(0.25), theme.softBreak.spacing)
  }

  func testGitHubThemeWithSoftBreak() {
    // given
    let theme = Theme.gitHub
      .softBreak {
        Spacing(.em(0.25))
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.em(0.25), theme.softBreak.spacing)
  }

  func testBasicThemeWithSoftBreak() {
    // given
    let theme = Theme.basic
      .softBreak {
        Spacing(.rem(0.5))
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.rem(0.5), theme.softBreak.spacing)
  }

  func testDocCThemeWithSoftBreak() {
    // given
    let theme = Theme.docC
      .softBreak {
        Spacing(.em(0.3))
      }

    // then
    XCTAssertNotNil(theme.softBreak.spacing)
    XCTAssertEqual(.em(0.3), theme.softBreak.spacing)
  }

  // MARK: - Empty Builder Tests

  func testThemeSoftBreakEmptyBuilder() {
    // given
    @TextStyleBuilder func empty() -> some TextStyle {}

    let theme = Theme()
      .softBreak(softBreak: empty)

    // then - empty builder should not set spacing
    XCTAssertNil(theme.softBreak.spacing)
  }

  // MARK: - Override Tests

  func testThemeSoftBreakCanBeOverridden() {
    // given
    let theme1 = Theme()
      .softBreak {
        Spacing(.em(0.5))
      }

    let theme2 = theme1
      .softBreak {
        Spacing(.rem(1))
      }

    // then - second call should override
    XCTAssertEqual(.rem(1), theme2.softBreak.spacing)
  }

  func testSoftBreakStyleMutation() {
    // given
    var style = SoftBreakStyle.default

    // when
    style.spacing = .em(0.5)

    // then
    XCTAssertEqual(.em(0.5), style.spacing)
  }
}
