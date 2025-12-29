import Foundation

// MARK: - Image Dimension Protection

/// Placeholder character used to protect | in image dimensions from table parsing.
/// Using Unicode Private Use Area character U+E000.
private let imageDimensionPlaceholder = "\u{E000}"

extension String {
  /// Protects image dimension syntax from the table parser by replacing | with a placeholder.
  /// Returns the modified string and whether any replacements were made.
  ///
  /// Matches patterns like: ![alt|100](url) or ![alt|100x200](url)
  func protectingImageDimensions() -> (result: String, hasImageDimensions: Bool) {
    // Pattern matches ![...](...)  where the alt text contains |
    // We need to be careful to match balanced brackets
    let pattern = #"!\[([^\]]*\|[^\]]*)\]\(([^)]+)\)"#

    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
      return (self, false)
    }

    var result = self
    var hasReplacements = false
    let nsRange = NSRange(self.startIndex..., in: self)

    // Process matches in reverse order to maintain correct indices
    let matches = regex.matches(in: self, options: [], range: nsRange).reversed()

    for match in matches {
      guard let fullRange = Range(match.range, in: result),
            let altRange = Range(match.range(at: 1), in: result),
            let urlRange = Range(match.range(at: 2), in: result) else { continue }

      let altText = String(result[altRange])
      let url = String(result[urlRange])

      // Replace | with placeholder in alt text only
      let protectedAlt = altText.replacingOccurrences(of: "|", with: imageDimensionPlaceholder)
      let replacement = "![\(protectedAlt)](\(url))"

      result.replaceSubrange(fullRange, with: replacement)
      hasReplacements = true
    }

    return (result, hasReplacements)
  }
}

extension Array where Element == BlockNode {
  /// Restores image dimension placeholders back to | characters.
  func restoringImageDimensions() -> [BlockNode] {
    self.map { block in
      block.restoringImageDimensions()
    }
  }
}

extension BlockNode {
  /// Restores image dimension placeholders in this block.
  fileprivate func restoringImageDimensions() -> BlockNode {
    switch self {
    case .blockquote(let children):
      return .blockquote(children: children.restoringImageDimensions())

    case .callout(let type, let title, let children):
      return .callout(type: type, title: title, children: children.restoringImageDimensions())

    case .bulletedList(let isTight, let items):
      return .bulletedList(
        isTight: isTight,
        items: items.map { RawListItem(children: $0.children.restoringImageDimensions()) }
      )

    case .numberedList(let isTight, let start, let items):
      return .numberedList(
        isTight: isTight,
        start: start,
        items: items.map { RawListItem(children: $0.children.restoringImageDimensions()) }
      )

    case .taskList(let isTight, let items):
      return .taskList(
        isTight: isTight,
        items: items.map {
          RawTaskListItem(isCompleted: $0.isCompleted, children: $0.children.restoringImageDimensions())
        }
      )

    case .paragraph(let content):
      return .paragraph(content: content.restoringImageDimensions())

    case .heading(let level, let content):
      return .heading(level: level, content: content.restoringImageDimensions())

    case .table(let columnAlignments, let rows):
      return .table(
        columnAlignments: columnAlignments,
        rows: rows.map { row in
          RawTableRow(cells: row.cells.map { cell in
            RawTableCell(content: cell.content.restoringImageDimensions())
          })
        }
      )

    default:
      return self
    }
  }
}

extension Array where Element == InlineNode {
  /// Restores image dimension placeholders in inline nodes.
  fileprivate func restoringImageDimensions() -> [InlineNode] {
    self.map { $0.restoringImageDimensions() }
  }
}

extension InlineNode {
  /// Restores image dimension placeholders in this inline node.
  fileprivate func restoringImageDimensions() -> InlineNode {
    switch self {
    case .text(let content):
      return .text(content.replacingOccurrences(of: imageDimensionPlaceholder, with: "|"))

    case .image(let source, let children):
      // Restore | in the alt text (children)
      return .image(source: source, children: children.restoringImageDimensions())

    case .emphasis(let children):
      return .emphasis(children: children.restoringImageDimensions())

    case .strong(let children):
      return .strong(children: children.restoringImageDimensions())

    case .strikethrough(let children):
      return .strikethrough(children: children.restoringImageDimensions())

    case .highlight(let children):
      return .highlight(children: children.restoringImageDimensions())

    case .link(let destination, let children):
      return .link(destination: destination, children: children.restoringImageDimensions())

    default:
      return self
    }
  }
}

// MARK: - Highlight Syntax (==text==)

extension Array where Element == InlineNode {
  /// Rewrites text nodes to parse ==highlight== syntax into .highlight nodes.
  func applyHighlightSyntax() -> [InlineNode] {
    self.flatMap { node -> [InlineNode] in
      switch node {
      case .text(let content):
        return parseHighlights(in: content)
      case .emphasis(let children):
        return [.emphasis(children: children.applyHighlightSyntax())]
      case .strong(let children):
        return [.strong(children: children.applyHighlightSyntax())]
      case .strikethrough(let children):
        return [.strikethrough(children: children.applyHighlightSyntax())]
      case .highlight(let children):
        return [.highlight(children: children.applyHighlightSyntax())]
      case .link(let destination, let children):
        return [.link(destination: destination, children: children.applyHighlightSyntax())]
      case .image(let source, let children):
        return [.image(source: source, children: children.applyHighlightSyntax())]
      default:
        return [node]
      }
    }
  }
}

/// Parses highlight syntax (==text==) in a text string.
private func parseHighlights(in text: String) -> [InlineNode] {
  let pattern = "==(.+?)=="
  guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
    return [.text(text)]
  }

  var results: [InlineNode] = []
  var lastEnd = text.startIndex

  let nsRange = NSRange(text.startIndex..., in: text)
  regex.enumerateMatches(in: text, options: [], range: nsRange) { match, _, _ in
    guard let match = match,
          let fullRange = Range(match.range, in: text),
          let contentRange = Range(match.range(at: 1), in: text) else { return }

    // Text before the match
    if lastEnd < fullRange.lowerBound {
      let beforeText = String(text[lastEnd..<fullRange.lowerBound])
      if !beforeText.isEmpty {
        results.append(.text(beforeText))
      }
    }

    // The highlighted content
    let highlightedText = String(text[contentRange])
    results.append(.highlight(children: [.text(highlightedText)]))

    lastEnd = fullRange.upperBound
  }

  // Remaining text after the last match
  if lastEnd < text.endIndex {
    let remainingText = String(text[lastEnd...])
    if !remainingText.isEmpty {
      results.append(.text(remainingText))
    }
  }

  return results.isEmpty ? [.text(text)] : results
}

// MARK: - Callout Syntax (> [!type])

extension Array where Element == BlockNode {
  /// Rewrites blockquotes that start with [!type] into .callout nodes.
  func applyCalloutSyntax() -> [BlockNode] {
    self.flatMap { node -> [BlockNode] in
      switch node {
      case .blockquote(let children):
        if let callout = parseCallout(from: children) {
          return [callout]
        }
        // Recursively process nested blockquotes
        return [.blockquote(children: children.applyCalloutSyntax())]

      case .callout(let type, let title, let children):
        return [.callout(type: type, title: title, children: children.applyCalloutSyntax())]

      case .bulletedList(let isTight, let items):
        return [.bulletedList(
          isTight: isTight,
          items: items.map { RawListItem(children: $0.children.applyCalloutSyntax()) }
        )]

      case .numberedList(let isTight, let start, let items):
        return [.numberedList(
          isTight: isTight,
          start: start,
          items: items.map { RawListItem(children: $0.children.applyCalloutSyntax()) }
        )]

      case .taskList(let isTight, let items):
        return [.taskList(
          isTight: isTight,
          items: items.map {
            RawTaskListItem(isCompleted: $0.isCompleted, children: $0.children.applyCalloutSyntax())
          }
        )]

      default:
        return [node]
      }
    }
  }
}

/// Attempts to parse a blockquote's children as a callout.
/// Returns a .callout node if the blockquote starts with [!type] (Obsidian) or **Type** (GitHub), otherwise nil.
private func parseCallout(from children: [BlockNode]) -> BlockNode? {
  guard let firstChild = children.first,
        case .paragraph(let inlines) = firstChild,
        let firstInline = inlines.first else {
    return nil
  }

  // Try Obsidian-style first: [!type] or [!type] Optional Title
  if case .text(let text) = firstInline {
    if let result = parseObsidianCallout(text: text, inlines: inlines, children: children) {
      return result
    }
  }

  // Try GitHub-style: **Note**, **Warning**, etc.
  if let result = parseGitHubCallout(inlines: inlines, children: children) {
    return result
  }

  return nil
}

/// Callout types recognized for GitHub-style parsing (case-insensitive matching).
/// Includes all CalloutType values to provide parity with Obsidian-style callouts.
private let gitHubCalloutTypes: Set<String> = [
  // Info types
  "note", "abstract", "summary", "info", "todo",
  // Positive types
  "tip", "hint", "important", "success", "check", "done",
  // Question types
  "question", "help", "faq",
  // Warning types
  "warning", "caution", "attention",
  // Error types
  "failure", "fail", "missing", "danger", "error", "bug",
  // Other types
  "example", "quote", "cite"
]

/// Parses Obsidian-style callouts: [!type] or [!type] Optional Title
private func parseObsidianCallout(text: String, inlines: [InlineNode], children: [BlockNode]) -> BlockNode? {
  // Pattern: [!type] or [!type] Optional Title
  // The type can contain letters, numbers, hyphens, and underscores
  let pattern = #"^\[!([a-zA-Z0-9_-]+)\](?:\s+(.+))?"#
  guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
        let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
        let typeRange = Range(match.range(at: 1), in: text) else {
    return nil
  }

  let calloutType = String(text[typeRange]).lowercased()

  // Extract optional title
  var title: String? = nil
  if match.range(at: 2).location != NSNotFound,
     let titleRange = Range(match.range(at: 2), in: text) {
    title = String(text[titleRange])
  }

  // Process the remaining content
  var modifiedChildren = children

  // Get the text after [!type] and optional title on the first line
  let matchEndIndex = text.index(text.startIndex, offsetBy: match.range.length)
  let remainingFirstLineText = String(text[matchEndIndex...]).trimmingCharacters(in: .whitespaces)

  if remainingFirstLineText.isEmpty && inlines.count == 1 {
    // The entire first paragraph was just the callout marker
    modifiedChildren.removeFirst()
  } else if remainingFirstLineText.isEmpty && inlines.count > 1 {
    // Remove just the first text node, keep other inlines
    var newInlines = Array(inlines.dropFirst())
    // Clean up leading soft breaks
    while let first = newInlines.first {
      if case .softBreak = first {
        newInlines.removeFirst()
      } else if case .text(let t) = first, t.trimmingCharacters(in: .whitespaces).isEmpty {
        newInlines.removeFirst()
      } else {
        break
      }
    }
    if newInlines.isEmpty {
      modifiedChildren.removeFirst()
    } else {
      modifiedChildren[0] = .paragraph(content: newInlines)
    }
  } else {
    // There's remaining text on the first line
    var newInlines = inlines
    newInlines[0] = .text(remainingFirstLineText)
    modifiedChildren[0] = .paragraph(content: newInlines)
  }

  // Recursively process any nested callouts in the content
  modifiedChildren = modifiedChildren.applyCalloutSyntax()

  return .callout(type: calloutType, title: title, children: modifiedChildren)
}

/// Parses GitHub-style callouts: > **Note**, > **Warning**, etc.
/// GitHub format: The first element is a strong (bold) containing just the type name
private func parseGitHubCallout(inlines: [InlineNode], children: [BlockNode]) -> BlockNode? {
  guard let firstInline = inlines.first,
        case .strong(let strongChildren) = firstInline,
        strongChildren.count == 1,
        case .text(let typeText) = strongChildren.first else {
    return nil
  }

  // Check if this is a recognized GitHub callout type
  let calloutType = typeText.trimmingCharacters(in: .whitespaces).lowercased()
  guard gitHubCalloutTypes.contains(calloutType) else {
    return nil
  }

  // Process the remaining content after the **Type** marker
  var modifiedChildren = children

  if inlines.count == 1 {
    // The entire first paragraph was just the **Type** marker
    modifiedChildren.removeFirst()
  } else {
    // Remove the **Type** marker and clean up leading whitespace/breaks
    var newInlines = Array(inlines.dropFirst())

    // Clean up leading soft breaks and whitespace
    while let first = newInlines.first {
      if case .softBreak = first {
        newInlines.removeFirst()
      } else if case .text(let t) = first {
        let leadingTrimmed = t.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        if leadingTrimmed.isEmpty {
          newInlines.removeFirst()
        } else if t != leadingTrimmed {
          // Replace with version that has leading whitespace removed (preserve trailing)
          newInlines[0] = .text(leadingTrimmed)
          break
        } else {
          break
        }
      } else {
        break
      }
    }

    if newInlines.isEmpty {
      modifiedChildren.removeFirst()
    } else {
      modifiedChildren[0] = .paragraph(content: newInlines)
    }
  }

  // Recursively process any nested callouts in the content
  modifiedChildren = modifiedChildren.applyCalloutSyntax()

  return .callout(type: calloutType, title: nil, children: modifiedChildren)
}

// MARK: - Combined Extension Application

extension Array where Element == BlockNode {
  /// Applies all Obsidian markdown extensions (callouts and highlights).
  func applyObsidianExtensions() -> [BlockNode] {
    self
      .applyCalloutSyntax()
      .applyHighlightSyntaxToBlocks()
  }

  /// Applies highlight syntax to all inline content within blocks.
  private func applyHighlightSyntaxToBlocks() -> [BlockNode] {
    self.map { block -> BlockNode in
      switch block {
      case .blockquote(let children):
        return .blockquote(children: children.applyHighlightSyntaxToBlocks())

      case .callout(let type, let title, let children):
        return .callout(type: type, title: title, children: children.applyHighlightSyntaxToBlocks())

      case .bulletedList(let isTight, let items):
        return .bulletedList(
          isTight: isTight,
          items: items.map { RawListItem(children: $0.children.applyHighlightSyntaxToBlocks()) }
        )

      case .numberedList(let isTight, let start, let items):
        return .numberedList(
          isTight: isTight,
          start: start,
          items: items.map { RawListItem(children: $0.children.applyHighlightSyntaxToBlocks()) }
        )

      case .taskList(let isTight, let items):
        return .taskList(
          isTight: isTight,
          items: items.map {
            RawTaskListItem(isCompleted: $0.isCompleted, children: $0.children.applyHighlightSyntaxToBlocks())
          }
        )

      case .paragraph(let content):
        return .paragraph(content: content.applyHighlightSyntax())

      case .heading(let level, let content):
        return .heading(level: level, content: content.applyHighlightSyntax())

      case .table(let columnAlignments, let rows):
        return .table(
          columnAlignments: columnAlignments,
          rows: rows.map { row in
            RawTableRow(cells: row.cells.map { cell in
              RawTableCell(content: cell.content.applyHighlightSyntax())
            })
          }
        )

      default:
        return block
      }
    }
  }
}
