import MarkdownUI
import XCTest

final class MarkdownContentTests: XCTestCase {
  func testEmpty() {
    // when
    let content = MarkdownContent("")

    // then
    XCTAssertEqual(MarkdownContent {}, content)
    XCTAssertEqual("", content.renderMarkdown())
  }

  func testBlockquote() {
    // given
    let markdown = """
      > Hello
      >\u{20}
      > > World
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Blockquote {
          "Hello"
          Blockquote {
            "World"
          }
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testList() {
    // given
    let markdown = """
      1.  one
      2.  two
            - nested 1
            - nested 2
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        NumberedList {
          "one"
          ListItem {
            "two"
            BulletedList {
              "nested 1"
              "nested 2"
            }
          }
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testLooseList() {
    // given
    let markdown = """
      9.  one

      10. two
      \u{20}\u{20}\u{20}\u{20}
            - nested 1
            - nested 2
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        NumberedList(tight: false, start: 9) {
          "one"
          ListItem {
            "two"
            BulletedList {
              "nested 1"
              "nested 2"
            }
          }
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testTaskList() {
    // given
    let markdown = """
      - [ ] one
      - [x] two
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        TaskList {
          "one"
          TaskListItem(isCompleted: true) {
            "two"
          }
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testCodeBlock() {
    // given
    let markdown = """
      ``` swift
      let a = 5
      let b = 42
      ```
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        CodeBlock(language: "swift") {
          """
          let a = 5
          let b = 42

          """
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testParagraph() {
    // given
    let markdown = "Hello world\\!"

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello world!"
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testHeading() {
    // given
    let markdown = """
      # Hello

      ## World
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Heading {
          "Hello"
        }
        Heading(.level2) {
          "World"
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testTable() throws {
    guard #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) else {
      throw XCTSkip("Required API is not available for this test")
    }

    // given
    let markdown = """
      |Default|Leading|Center|Trailing|
      | --- | :-- | :-: | --: |
      |git status|git status|git status|git status|
      |git diff|git diff|git diff|git diff|
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        TextTable {
          TextTableColumn<[String]>(title: "Default", value: \.[0])
          TextTableColumn(alignment: .leading, title: "Leading", value: \.[1])
          TextTableColumn(alignment: .center, title: "Center", value: \.[2])
          TextTableColumn(alignment: .trailing, title: "Trailing", value: \.[3])
        } rows: {
          TextTableRow(Array(repeating: "git status", count: 4))
          TextTableRow(Array(repeating: "git diff", count: 4))
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testThematicBreak() {
    // given
    let markdown = """
      Foo

      -----

      Bar
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        "Foo"
        ThematicBreak()
        "Bar"
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testSoftBreak() {
    // given
    let markdown = "Hello\nWorld"

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello"
          SoftBreak()
          "World"
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testLineBreak() {
    // given
    let markdown = "Hello  \nWorld"

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello"
          LineBreak()
          "World"
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testCode() {
    // given
    let markdown = "Returns `nil`."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Returns "
          Code("nil")
          "."
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testEmphasis() {
    // given
    let markdown = "Hello *world*."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello "
          Emphasis("world")
          "."
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testStrong() {
    // given
    let markdown = "Hello **world**."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello "
          Strong("world")
          "."
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testStrikethrough() {
    // given
    let markdown = "Hello ~~world~~."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello "
          Strikethrough("world")
          "."
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testLink() {
    // given
    let markdown = "Hello [world](https://example.com)."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello "
          InlineLink("world", destination: URL(string: "https://example.com")!)
          "."
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testImage() {
    // given
    let markdown = "![Puppy](https://picsum.photos/id/237/200/300)"

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          InlineImage("Puppy", source: URL(string: "https://picsum.photos/id/237/200/300")!)
        }
      },
      content
    )
    XCTAssertEqual(markdown, content.renderMarkdown())
  }

  func testCallout() {
    // given
    let markdown = """
      > [!note]
      > Hello world
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.note) {
          "Hello world"
        }
      },
      content
    )
  }

  func testCalloutWithTitle() {
    // given
    let markdown = """
      > [!warning] Be Careful
      > This is important
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.warning, title: "Be Careful") {
          "This is important"
        }
      },
      content
    )
  }

  func testCalloutWithThaiText() {
    // Regression test for Unicode handling in callout parsing.
    // Thai script uses multi-codepoint grapheme clusters that previously
    // caused crashes due to incorrect NSRange to String.Index conversion.

    // given
    let markdown = """
      > [!note] หมายเหตุ
      > นี่คือข้อความภาษาไทย
      """

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.note, title: "หมายเหตุ") {
          "นี่คือข้อความภาษาไทย"
        }
      },
      content
    )
  }

  func testCalloutWithComplexUnicode() {
    // Test various complex Unicode scripts that have multi-codepoint grapheme clusters

    // given - Arabic text
    let arabicMarkdown = """
      > [!note] ملاحظة
      > هذا نص عربي
      """

    // when
    let arabicContent = MarkdownContent(arabicMarkdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.note, title: "ملاحظة") {
          "هذا نص عربي"
        }
      },
      arabicContent
    )

    // given - Hindi text with combining marks
    let hindiMarkdown = """
      > [!tip] सुझाव
      > यह हिंदी पाठ है
      """

    // when
    let hindiContent = MarkdownContent(hindiMarkdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.tip, title: "सुझाव") {
          "यह हिंदी पाठ है"
        }
      },
      hindiContent
    )

    // given - Emoji with ZWJ sequences
    let emojiMarkdown = """
      > [!info] 👨‍👩‍👧‍👦 Family
      > Content with emoji 🎉
      """

    // when
    let emojiContent = MarkdownContent(emojiMarkdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Callout(.info, title: "👨‍👩‍👧‍👦 Family") {
          "Content with emoji 🎉"
        }
      },
      emojiContent
    )
  }

  func testHighlight() {
    // given
    let markdown = "Hello ==world==."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Hello "
          Highlight("world")
          "."
        }
      },
      content
    )
  }

  func testHighlightWithNestedBold() {
    // Regression test: nested formatting inside highlights should be parsed correctly.
    // Previously, ==highlighted **bold** text== would incorrectly match " and " as highlighted
    // when multiple highlights were on the same line.

    // given
    let markdown = "This has ==highlighted **bold** text== here."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "This has "
          Highlight {
            "highlighted "
            Strong("bold")
            " text"
          }
          " here."
        }
      },
      content
    )
  }

  func testHighlightWithNestedItalic() {
    // given
    let markdown = "Check ==*italic* highlight== out."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "Check "
          Highlight {
            Emphasis("italic")
            " highlight"
          }
          " out."
        }
      },
      content
    )
  }

  func testMultipleHighlightsOnSameLine() {
    // Regression test: multiple highlights on the same line should be parsed independently.
    // Previously, ==first== and ==second== would incorrectly highlight " and " between them.

    // given
    let markdown = "This has ==first== and ==second== highlights."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "This has "
          Highlight("first")
          " and "
          Highlight("second")
          " highlights."
        }
      },
      content
    )
  }

  func testMultipleHighlightsWithNestedFormatting() {
    // Comprehensive test: multiple highlights with nested formatting on same line

    // given
    let markdown = "This paragraph has ==highlighted **bold** text== and ==*highlighted italic*== together."

    // when
    let content = MarkdownContent(markdown)

    // then
    XCTAssertEqual(
      MarkdownContent {
        Paragraph {
          "This paragraph has "
          Highlight {
            "highlighted "
            Strong("bold")
            " text"
          }
          " and "
          Highlight {
            Emphasis("highlighted italic")
          }
          " together."
        }
      },
      content
    )
  }
}
