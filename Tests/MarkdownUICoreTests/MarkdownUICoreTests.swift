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

    XCTAssertTrue(html.contains("<mark>highlighted</mark>"), "Expected <mark> tag in: \(html)")
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

  // MARK: - CriticMarkup Parsing Tests

  func testCriticMarkupAdditionParsing() {
    let markdown = "This is {++an addition++} in text."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph(let inlines) = blocks[0] {
      // Should contain a criticAddition node
      let hasAddition = inlines.contains { inline in
        if case .criticAddition = inline { return true }
        return false
      }
      XCTAssertTrue(hasAddition, "Expected criticAddition node in inlines")
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  func testCriticMarkupDeletionParsing() {
    let markdown = "This is {--a deletion--} in text."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph(let inlines) = blocks[0] {
      let hasDeletion = inlines.contains { inline in
        if case .criticDeletion = inline { return true }
        return false
      }
      XCTAssertTrue(hasDeletion, "Expected criticDeletion node in inlines")
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  func testCriticMarkupSubstitutionParsing() {
    let markdown = "Replace {~~old~>new~~} text."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph(let inlines) = blocks[0] {
      let hasSubstitution = inlines.contains { inline in
        if case .criticSubstitution = inline { return true }
        return false
      }
      XCTAssertTrue(hasSubstitution, "Expected criticSubstitution node in inlines")
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  func testCriticMarkupCommentParsing() {
    let markdown = "This has {>>a comment<<} inline."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph(let inlines) = blocks[0] {
      let hasComment = inlines.contains { inline in
        if case .criticComment = inline { return true }
        return false
      }
      XCTAssertTrue(hasComment, "Expected criticComment node in inlines")
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  func testCriticMarkupHighlightParsing() {
    let markdown = "This is {==highlighted text==} here."
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .paragraph(let inlines) = blocks[0] {
      let hasHighlight = inlines.contains { inline in
        if case .criticHighlight = inline { return true }
        return false
      }
      XCTAssertTrue(hasHighlight, "Expected criticHighlight node in inlines")
    } else {
      XCTFail("Expected paragraph block")
    }
  }

  // MARK: - CriticMarkup HTML Rendering Tests

  func testCriticMarkupAdditionHTMLRendering() {
    let markdown = "This is {++added++} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">added</ins>"))
  }

  func testCriticMarkupDeletionHTMLRendering() {
    let markdown = "This is {--deleted--} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-deletion\">deleted</del>"))
  }

  func testCriticMarkupSubstitutionHTMLRendering() {
    let markdown = "Replace {~~old~>new~~} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\">old</del>"))
    XCTAssertTrue(html.contains("<ins class=\"critic-substitution-new\">new</ins>"))
  }

  func testCriticMarkupCommentHTMLRendering() {
    let markdown = "This has {>>a comment<<} inline."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<span class=\"critic-comment\">a comment</span>"))
  }

  func testCriticMarkupHighlightHTMLRendering() {
    let markdown = "This is {==highlighted==} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<mark class=\"critic-highlight\">highlighted</mark>"))
  }

  // MARK: - CriticMarkup in Code Blocks (should NOT render)

  func testCriticMarkupInCodeBlockPreservesOriginalSyntax() {
    let markdown = """
    ```
    {++This should NOT render as an addition++}
    {--This should NOT render as a deletion--}
    {~~old~>new~~}
    ```
    """
    let blocks = [BlockNode](markdown: markdown)

    XCTAssertEqual(blocks.count, 1)
    if case .codeBlock(_, let content) = blocks[0] {
      // Code blocks should contain original syntax, not placeholders
      XCTAssertTrue(content.contains("{++"))
      XCTAssertTrue(content.contains("++}"))
      XCTAssertTrue(content.contains("{--"))
      XCTAssertTrue(content.contains("--}"))
      XCTAssertTrue(content.contains("{~~"))
      XCTAssertTrue(content.contains("~>"))
      XCTAssertTrue(content.contains("~~}"))
      // Should NOT contain placeholder characters (U+E010-U+E01A)
      let hasPlaceholders = content.unicodeScalars.contains { $0.value >= 0xE010 && $0.value <= 0xE01A }
      XCTAssertFalse(hasPlaceholders, "Code blocks should not contain placeholder characters")
    } else {
      XCTFail("Expected code block")
    }
  }

  // MARK: - CriticMarkup Edge Cases

  func testCriticMarkupEmptyContent() {
    // Empty additions/deletions should not be parsed as CriticMarkup
    let markdown = "{++++} {----} {~~old~>~~}"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Empty content edge cases - these may or may not parse depending on implementation
    // At minimum, no crash should occur
    XCTAssertFalse(html.isEmpty)
  }

  func testCriticMarkupWithPlainContent() {
    // CriticMarkup works correctly with plain text content
    let markdown = "This has {++simple addition++} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">simple addition</ins>"))
  }

  func testCriticMarkupNestedFormattingLimitation() {
    // Known limitation: Nested markdown formatting inside CriticMarkup may not work correctly.
    // When cmark parses **bold** inside {++...++}, it creates nested inline nodes
    // that can disrupt the placeholder pattern.
    // This test documents the current behavior.
    let markdown = "This has {++**bold**++} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // At minimum, should not crash and should produce some output
    XCTAssertFalse(html.isEmpty)
    // The content "bold" should appear somewhere in the output
    XCTAssertTrue(html.contains("bold"))
  }

  func testCriticMarkupMultipleInOneLine() {
    let markdown = "The {~~quick~>fast~~} {++brown++} fox {--jumped--} over."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\">quick</del>"))
    XCTAssertTrue(html.contains("<ins class=\"critic-substitution-new\">fast</ins>"))
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">brown</ins>"))
    XCTAssertTrue(html.contains("<del class=\"critic-deletion\">jumped</del>"))
  }

  func testCriticMarkupInHeading() {
    let markdown = "## This heading has {++an addition++}"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<h2"))
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">an addition</ins>"))
  }

  func testCriticMarkupInTableCell() {
    let markdown = """
    | Column |
    |--------|
    | {++added++} |
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<table"))
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">added</ins>"))
  }

  func testCriticMarkupInListItem() {
    let markdown = """
    - Item with {++addition++}
    - Item with {--deletion--}
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<li>"))
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">addition</ins>"))
    XCTAssertTrue(html.contains("<del class=\"critic-deletion\">deletion</del>"))
  }

  func testCriticMarkupMissingCloseMarker() {
    // Unclosed CriticMarkup should output original syntax as text
    let markdown = "This has {++unclosed addition"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Should contain the original {++ as text, not as markup
    XCTAssertTrue(html.contains("{++") || html.contains("unclosed addition"))
    // Should not crash
    XCTAssertFalse(html.isEmpty)
  }

  func testCriticMarkupMixedWithObsidianHighlight() {
    let markdown = "Obsidian ==highlight== and CriticMarkup {==highlight==}."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Both should render as highlight elements
    // Obsidian ==text== renders as <mark>text</mark>
    // CriticMarkup {==text==} renders as <mark class="critic-highlight">text</mark>
    XCTAssertTrue(html.contains("<mark"))
    XCTAssertTrue(html.contains("highlight"))
    // At least one highlight should have the critic-highlight class
    XCTAssertTrue(html.contains("critic-highlight"))
  }

  func testCriticMarkupInCallout() {
    let markdown = """
    > [!note]
    > This note has {++an addition++} inside.
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("class=\"callout callout-note\""))
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">an addition</ins>"))
  }
}
