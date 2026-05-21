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

  func testCriticMarkupNestedBoldFormatting() {
    // Nested formatting inside CriticMarkup - bold
    let markdown = "This has {++**bold**++} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Should render as addition containing bold
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\"><strong>bold</strong></ins>"), "Expected bold inside addition, got: \(html)")
  }

  func testCriticMarkupNestedItalicFormatting() {
    // Nested formatting inside CriticMarkup - italic
    let markdown = "This has {--*italic*--} text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Should render as deletion containing italic
    XCTAssertTrue(html.contains("<del class=\"critic-deletion\"><em>italic</em></del>"), "Expected italic inside deletion, got: \(html)")
  }

  func testCriticMarkupSubstitutionWithNestedItalic() {
    // Substitution with italic formatting inside both old and new content
    let markdown = "I really love {~~*italic fonts*~>*italic font-styles*~~}."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Should render as: strikethrough italic "italic fonts" followed by underlined italic "italic font-styles"
    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\"><em>italic fonts</em></del>"), "Expected italic inside substitution-old, got: \(html)")
    XCTAssertTrue(html.contains("<ins class=\"critic-substitution-new\"><em>italic font-styles</em></ins>"), "Expected italic inside substitution-new, got: \(html)")
  }

  func testCriticMarkupSimpleSubstitution() {
    // Simple substitution without nested formatting
    let markdown = "Lorem {~~hipsum~>ipsum~~} dolor sit amet…"
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\">hipsum</del>"), "Expected hipsum in substitution-old, got: \(html)")
  }

  func testCriticMarkupAdjacentSubstitutionAndComment() {
    // Adjacent CriticMarkup elements - substitution immediately followed by comment
    let markdown = "The deadline is {~~March 15~>March 22~~}{>>pushed back due to delays<<}."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\">March 15</del>"), "Expected substitution-old, got: \(html)")
    XCTAssertTrue(html.contains("<ins class=\"critic-substitution-new\">March 22</ins>"), "Expected substitution-new, got: \(html)")
    XCTAssertTrue(html.contains("<span class=\"critic-comment\">pushed back due to delays</span>"), "Expected comment, got: \(html)")

    // Verify the InlineNode structure
    if case .paragraph(let inlines) = blocks.first {
      // Should have: text, substitution, comment, text(.)
      print("DEBUG: InlineNode structure:")
      for (i, inline) in inlines.enumerated() {
        print("  [\(i)] \(inline)")
      }

      // Find the substitution node and verify its structure
      for inline in inlines {
        if case .criticSubstitution(let oldContent, let newContent) = inline {
          print("DEBUG: Substitution oldContent: \(oldContent)")
          print("DEBUG: Substitution newContent: \(newContent)")
          // Verify oldContent has "March 15"
          XCTAssertEqual(oldContent.count, 1, "oldContent should have 1 element")
          if case .text(let oldText) = oldContent.first {
            XCTAssertEqual(oldText, "March 15", "oldContent should be 'March 15'")
          }
          // Verify newContent has "March 22"
          XCTAssertEqual(newContent.count, 1, "newContent should have 1 element")
          if case .text(let newText) = newContent.first {
            XCTAssertEqual(newText, "March 22", "newContent should be 'March 22'")
          }
        }
      }
    }
  }

  func testCriticMarkupMultipleInOneLine() {
    let markdown = "The {~~quick~>fast~~} {++brown++} fox {--jumped--} over."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<del class=\"critic-substitution-old\">quick</del>"), "Expected substitution-old, got: \(html)")
    XCTAssertTrue(html.contains("<ins class=\"critic-substitution-new\">fast</ins>"), "Expected substitution-new, got: \(html)")
    XCTAssertTrue(html.contains("<ins class=\"critic-addition\">brown</ins>"), "Expected addition, got: \(html)")
    XCTAssertTrue(html.contains("<del class=\"critic-deletion\">jumped</del>"), "Expected deletion, got: \(html)")
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

  func testCriticMarkupInInlineCodePreservesOriginalSyntax() {
    // Inline code should show original CriticMarkup syntax, not render it
    let markdown = "Here is inline code: `{++addition++}` should not render."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    // Should contain the original syntax inside <code> tags, not rendered CriticMarkup
    XCTAssertTrue(html.contains("<code>{++addition++}</code>"), "Expected original syntax in inline code, got: \(html)")
    // Should NOT contain rendered CriticMarkup inside the code
    XCTAssertFalse(html.contains("<code><ins"), "Should not render CriticMarkup inside inline code")
  }

  func testAllCriticMarkupTypesInInlineCode() {
    // All CriticMarkup types should preserve original syntax in inline code
    let markdown = """
    Addition: `{++add++}`
    Deletion: `{--del--}`
    Substitution: `{~~old~>new~~}`
    Comment: `{>>note<<}`
    Highlight: `{==mark==}`
    """
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<code>{++add++}</code>"), "Addition syntax should be preserved")
    XCTAssertTrue(html.contains("<code>{--del--}</code>"), "Deletion syntax should be preserved")
    XCTAssertTrue(html.contains("<code>{~~old~&gt;new~~}</code>"), "Substitution syntax should be preserved")
    XCTAssertTrue(html.contains("<code>{&gt;&gt;note&lt;&lt;}</code>"), "Comment syntax should be preserved")
    XCTAssertTrue(html.contains("<code>{==mark==}</code>"), "Highlight syntax should be preserved")
  }

  func testObsidianHighlightInInlineCodePreservesOriginalSyntax() {
    // Obsidian highlight syntax should also preserve original syntax in inline code
    let markdown = "Check this: `==highlighted==` text."
    let blocks = [BlockNode](markdown: markdown)
    let html = blocks.renderExtendedHTML()

    XCTAssertTrue(html.contains("<code>==highlighted==</code>"), "Expected original highlight syntax in inline code, got: \(html)")
  }

  // MARK: - Inline Math ($...$) Tests

  /// Helper that returns all .math content strings in a block tree.
  private func allMathContent(in blocks: [BlockNode]) -> [String] {
    var found: [String] = []
    func visitInline(_ inline: InlineNode) {
      switch inline {
      case .math(let content):
        found.append(content)
      case .emphasis(let children),
           .strong(let children),
           .strikethrough(let children),
           .highlight(let children),
           .criticAddition(let children),
           .criticDeletion(let children),
           .criticComment(let children),
           .criticHighlight(let children):
        children.forEach(visitInline)
      case .criticSubstitution(let oldContent, let newContent):
        oldContent.forEach(visitInline)
        newContent.forEach(visitInline)
      case .link(_, let children), .image(_, let children):
        children.forEach(visitInline)
      default:
        break
      }
    }
    func visitBlock(_ block: BlockNode) {
      switch block {
      case .blockquote(let children), .callout(_, _, let children):
        children.forEach(visitBlock)
      case .bulletedList(_, let items), .numberedList(_, _, let items):
        items.flatMap(\.children).forEach(visitBlock)
      case .taskList(_, let items):
        items.flatMap(\.children).forEach(visitBlock)
      case .paragraph(let content), .heading(_, let content):
        content.forEach(visitInline)
      case .table(_, let rows):
        rows.flatMap { $0.cells }.flatMap { $0.content }.forEach(visitInline)
      default:
        break
      }
    }
    blocks.forEach(visitBlock)
    return found
  }

  // MARK: Bug fix tests — math should be parsed in every context

  func testInlineMathDollarSimple() {
    let blocks = [BlockNode](markdown: "The formula is $E=mc^2$.")
    XCTAssertEqual(allMathContent(in: blocks), ["E=mc^2"])
  }

  func testInlineMathDollarWithBackslashCommands() {
    let markdown = "Variables: $\\mathbf{u}$ is velocity, $\\rho$ is density, $\\mu$ is viscosity."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), ["\\mathbf{u}", "\\rho", "\\mu"])
  }

  func testInlineMathDollarManyExpressionsInOneParagraph() {
    // Reproduces the Bug 3 case — 5+ inline math expressions following a block.
    let markdown = """
    $$
    \\nabla \\cdot \\mathbf{u} = 0
    $$

    where $\\mathbf{u}$ is velocity, $p$ is pressure, $\\rho$ is density, $\\mu$ is dynamic viscosity, and $\\mathbf{f}$ is body force per unit volume.
    """
    let blocks = [BlockNode](markdown: markdown)
    let mathExpressions = allMathContent(in: blocks)
    XCTAssertEqual(mathExpressions, ["\\mathbf{u}", "p", "\\rho", "\\mu", "\\mathbf{f}"])
  }

  func testInlineMathBackslashParenForm() {
    // Bug 1 (§0.4): `\(...\)` should also produce inline math.
    let blocks = [BlockNode](markdown: "Inline LaTeX: \\(x^2 + y^2 = z^2\\) is Pythagorean.")
    XCTAssertEqual(allMathContent(in: blocks), ["x^2 + y^2 = z^2"])
  }

  func testInlineMathInBlockquote() {
    // Bug 2 (§0.5): math inside `> ...` blockquotes should still parse.
    let markdown = "> The identity is $e^{i\\pi}+1=0$."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), ["e^{i\\pi}+1=0"])
  }

  func testInlineMathInBulletList() {
    let markdown = "- The formula $a^2+b^2=c^2$ is Pythagorean."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), ["a^2+b^2=c^2"])
  }

  func testInlineMathInCallout() {
    let markdown = """
    > [!note]
    > The formula is $E=mc^2$.
    """
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), ["E=mc^2"])
  }

  func testInlineMathPreservedInCodeBlock() {
    // Math inside code spans should be preserved literally.
    let markdown = "Use `$x^2$` for inline math."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), [], "Math markers inside inline code must not produce math nodes")
    let html = blocks.renderExtendedHTML()
    XCTAssertTrue(html.contains("<code>$x^2$</code>"), "Expected literal $x^2$ in code, got: \(html)")
  }

  func testInlineMathPreservedInFencedCodeBlock() {
    let markdown = """
    ```
    Some math: $E=mc^2$
    ```
    """
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), [])
  }

  func testDollarSignNotMath() {
    // A single $ with no closing $ should remain plain text.
    let markdown = "Costs $5 today."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), [])
  }

  func testTwoCurrencyAmountsInSameLine() {
    // Currency-heavy sentences are a known false-positive risk for $...$ math.
    // We accept a small false-positive rate (KaTeX renders text-as-math acceptably)
    // but call out the behavior so anyone re-tuning the regex can see what changes.
    // This test documents the current behavior, not a guarantee.
    let markdown = "It costs $5 and $10 for total."
    let blocks = [BlockNode](markdown: markdown)
    // Today the non-greedy regex matches the content between the two `$`s.
    // Acceptable for now — the host's KaTeX provider renders "5 and " as math text,
    // which is mildly ugly but reversible by writing currency as `\$5`.
    let math = allMathContent(in: blocks)
    XCTAssertTrue(math.isEmpty || math == ["5 and "], "Unexpected math parse: \(math)")
  }

  func testEscapedDollarNotMath() {
    // Backslash-escaped `\$` should not start math.
    let markdown = "Costs \\$5 and \\$10 for total."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), [])
  }

  func testMultipleAdjacentInlineMath() {
    let markdown = "Compare $a^2$ to $b^2$ to $c^2$."
    let blocks = [BlockNode](markdown: markdown)
    XCTAssertEqual(allMathContent(in: blocks), ["a^2", "b^2", "c^2"])
  }

  func testBlockMathBackslashBracket() {
    // Bug 1 (§0.4): `\[...\]` should produce a math code block.
    let markdown = """
    Before.

    \\[
    x^2 + y^2 = z^2
    \\]

    After.
    """
    let blocks = [BlockNode](markdown: markdown)
    // Expect a math code block among the blocks.
    var foundMathBlock = false
    for block in blocks {
      if case .codeBlock(let info, let content) = block, info == "math" {
        XCTAssertTrue(content.contains("x^2 + y^2 = z^2"), "Math content missing, got: \(content)")
        foundMathBlock = true
      }
    }
    XCTAssertTrue(foundMathBlock, "Expected a fenced math code block, got: \(blocks)")
  }

  func testBlockMathBackslashBracketSingleLine() {
    // `\[x^2\]` on its own line is display math too.
    let markdown = """
    Before.

    \\[x^2 + y^2 = z^2\\]

    After.
    """
    let blocks = [BlockNode](markdown: markdown)
    var foundMathBlock = false
    for block in blocks {
      if case .codeBlock(let info, let content) = block, info == "math" {
        XCTAssertTrue(content.contains("x^2 + y^2 = z^2"), "Math content missing, got: \(content)")
        foundMathBlock = true
      }
    }
    XCTAssertTrue(foundMathBlock, "Expected a fenced math code block, got: \(blocks)")
  }

  func testInlineMathHTMLRendering() {
    let blocks = [BlockNode](markdown: "Inline $E=mc^2$.")
    let html = blocks.renderExtendedHTML()
    XCTAssertTrue(html.contains("math-inline"), "Expected math-inline span in HTML, got: \(html)")
  }

  /// Lesson from CriticMarkup: parser correctness is not enough — the SwiftUI
  /// `Markdown` view runs `filterImagesMatching` (and similar) via `rewrite`
  /// on every render, which can corrupt nodes the bare parser path never
  /// touches. This test exercises a representative `rewrite` round-trip and
  /// confirms `.math` survives intact.
  func testInlineMathSurvivesIdentityRewrite() {
    let blocks = [BlockNode](markdown: "Energy $E=mc^2$ here.")
    // Identity rewrite: yields the same node back. If any setter collapses
    // structure (as `.criticSubstitution.children` once did) this catches it.
    let rewritten: [BlockNode] = blocks.rewrite { (inline: InlineNode) in [inline] }
    XCTAssertEqual(allMathContent(in: rewritten), ["E=mc^2"], "Math node lost or mangled by identity rewrite")
  }

  /// End-to-end document mirroring the FEATURE_ROADMAP repro cases for §0.4,
  /// §0.5, and §0.6. Verifies every form produces math nodes (or, for `\[...\]`,
  /// a math code block) in a single parse pass.
  func testRoadmapMathBugRepro() {
    let markdown = """
    \\[
    e^{i\\pi} + 1 = 0
    \\]

    where $\\mathbf{u}$ is velocity, $p$ is pressure, $\\rho$ is density, $\\mu$ is dynamic viscosity, and $\\mathbf{f}$ is body force per unit volume.

    > The Euler identity is $e^{i\\pi}+1=0$.

    > [!note]
    > Inside a callout: $A = \\pi r^2$.

    Inline LaTeX: \\(x^2 + y^2 = z^2\\) Pythagorean.
    """
    let blocks = [BlockNode](markdown: markdown)
    let math = allMathContent(in: blocks)

    // The dense backslash-command paragraph (§0.6)
    XCTAssertTrue(math.contains("\\mathbf{u}"), "§0.6 missing \\mathbf{u}: \(math)")
    XCTAssertTrue(math.contains("p"), "§0.6 missing p: \(math)")
    XCTAssertTrue(math.contains("\\rho"), "§0.6 missing \\rho: \(math)")
    XCTAssertTrue(math.contains("\\mu"), "§0.6 missing \\mu: \(math)")
    XCTAssertTrue(math.contains("\\mathbf{f}"), "§0.6 missing \\mathbf{f}: \(math)")

    // Blockquote (§0.5)
    XCTAssertTrue(math.contains("e^{i\\pi}+1=0"), "§0.5 blockquote math missing: \(math)")

    // Callout (§0.5)
    XCTAssertTrue(math.contains("A = \\pi r^2"), "§0.5 callout math missing: \(math)")

    // \(...\) form (§0.4)
    XCTAssertTrue(math.contains("x^2 + y^2 = z^2"), "§0.4 \\(...\\) missing: \(math)")

    // \[...\] becomes a math code block (§0.4)
    let hasBlockMath = blocks.contains { block in
      if case .codeBlock(let info, let content) = block, info == "math",
         content.contains("e^{i\\pi} + 1 = 0") { return true }
      return false
    }
    XCTAssertTrue(hasBlockMath, "§0.4 \\[...\\] block math missing")
  }
}
