import XCTest
@testable import MarkdownUICore

final class MarkdownUICoreTests: XCTestCase {

  // MARK: - Parsing Tests

  func testBasicMarkdownParsing() {
    let markdown = "# Hello World"
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .heading(let level, _) = blocks[0] {
      XCTAssertEqual(level, 1)
    } else {
      XCTFail("Expected heading block")
    }
  }

  func testParagraphParsing() {
    let markdown = "This is a paragraph."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph = blocks[0] {
      // Success
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  func testCodeBlockParsing() {
    let markdown = """
    ```swift
    let x = 42
    ```
    """
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .codeBlock(let info, let content) = blocks[0] {
      XCTAssertEqual(info, "swift")
      XCTAssertTrue(content.contains("let x = 42"))
    } else {
      XCTFail("Expected code block")
    }
  }

  func testCalloutParsing() {
    let markdown = """
    > [!note]
    > This is a note callout.
    """
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .callout(let type, let title, _) = blocks[0] {
      XCTAssertEqual(type, "note")
      XCTAssertNil(title)
    } else {
      XCTFail("Expected callout block, got: \(blocks[0])")
    }
  }

  func testCalloutWithCustomTitle() {
    let markdown = """
    > [!warning] Be Careful
    > This has a custom title.
    """
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .callout(let type, let title, _) = blocks[0] {
      XCTAssertEqual(type, "warning")
      XCTAssertEqual(title, "Be Careful")
    } else {
      XCTFail("Expected callout block")
    }
  }

  // MARK: - HTML Rendering Tests

  func testHeadingHTMLRendering() {
    let markdown = "# Hello World"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<h1"))
    XCTAssertTrue(html.contains("Hello World"))
    XCTAssertTrue(html.contains("</h1>"))
  }

  func testParagraphHTMLRendering() {
    let markdown = "This is **bold** and *italic*."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<p>"))
    XCTAssertTrue(html.contains("<strong>bold</strong>"))
    XCTAssertTrue(html.contains("<em>italic</em>"))
  }

  func testCodeBlockHTMLRendering() {
    let markdown = """
    ```python
    print("hello")
    ```
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<pre>"))
    XCTAssertTrue(html.contains("<code"))
    XCTAssertTrue(html.contains("language-python"))
  }

  func testCalloutHTMLRendering() {
    let markdown = """
    > [!tip]
    > A helpful tip.
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("class=\"callout callout-tip\""))
    XCTAssertTrue(html.contains("--callout-color:"))
    XCTAssertTrue(html.contains("callout-icon"))
    XCTAssertTrue(html.contains("callout-title"))
  }

  func testHighlightHTMLRendering() {
    let markdown = "This is ==highlighted== text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<mark>highlighted</mark>"))
  }

  func testTableHTMLRendering() {
    let markdown = """
    | A | B |
    |---|---|
    | 1 | 2 |
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<table>"))
    XCTAssertTrue(html.contains("<th>"))
    XCTAssertTrue(html.contains("<td>"))
  }

  func testTaskListHTMLRendering() {
    let markdown = """
    - [x] Done
    - [ ] Todo
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("task-list"))
    XCTAssertTrue(html.contains("checked"))
    XCTAssertTrue(html.contains("disabled"))
  }

  // MARK: - CalloutType Tests

  func testCalloutTypeFromRawValue() {
    XCTAssertEqual(CalloutType(rawValue: "note"), .note)
    XCTAssertEqual(CalloutType(rawValue: "NOTE"), .note)
    XCTAssertEqual(CalloutType(rawValue: "Warning"), .warning)
    XCTAssertNil(CalloutType(rawValue: "invalid"))
  }

  func testCalloutTypeCSSColor() {
    XCTAssertEqual(CalloutType.note.cssColor, "#3b82f6")
    XCTAssertEqual(CalloutType.warning.cssColor, "#f97316")
    XCTAssertEqual(CalloutType.danger.cssColor, "#ef4444")
    XCTAssertEqual(CalloutType.success.cssColor, "#22c55e")
  }

  func testCalloutTypeHTMLIcon() {
    XCTAssertEqual(CalloutType.note.htmlIcon, "✏️")
    XCTAssertEqual(CalloutType.tip.htmlIcon, "💡")
    XCTAssertEqual(CalloutType.warning.htmlIcon, "⚠️")
    XCTAssertEqual(CalloutType.bug.htmlIcon, "🐛")
  }

  func testCalloutTypeIconName() {
    XCTAssertEqual(CalloutType.note.iconName, "pencil")
    XCTAssertEqual(CalloutType.tip.iconName, "lightbulb")
    XCTAssertEqual(CalloutType.warning.iconName, "exclamationmark.triangle")
  }

  // MARK: - HTML Escaping Tests

  func testHTMLEscaping() {
    let markdown = "Use `<script>` tags carefully & avoid \"injection\"."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("&lt;script&gt;"))
    XCTAssertTrue(html.contains("&amp;"))
    XCTAssertTrue(html.contains("&quot;"))
  }

  // MARK: - Heading Slug Tests

  func testHeadingSlugGeneration() {
    let markdown = "## My Heading Title"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("id=\"my-heading-title\""))
  }
}
