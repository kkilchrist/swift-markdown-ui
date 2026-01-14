import Foundation

// MARK: - Placeholder Characters

/// Placeholder character used to protect | in image dimensions from table parsing.
/// Using Unicode Private Use Area character U+E000.
private let imageDimensionPlaceholder = "\u{E000}"

/// Placeholder characters for highlight markers to protect them from cmark parsing.
/// This allows nested formatting like ==**bold**== to be parsed correctly.
private let highlightOpenPlaceholder = "\u{E001}"
private let highlightClosePlaceholder = "\u{E002}"

/// Placeholder characters for inline math markers ($...$) to protect them from cmark parsing.
private let mathOpenPlaceholder = "\u{E003}"
private let mathClosePlaceholder = "\u{E004}"

/// Unicode Private Use Area range (U+E000 to U+F8FF)
private let privateUseAreaRange: ClosedRange<Unicode.Scalar> = "\u{E000}"..."\u{F8FF}"

public extension String {
  /// Strips Unicode Private Use Area characters from the string.
  /// These characters are reserved for application-specific use and shouldn't appear in normal text.
  public func strippingPrivateUseAreaCharacters() -> String {
    String(self.unicodeScalars.filter { !privateUseAreaRange.contains($0) })
  }
  /// Protects highlight syntax (==text==) from cmark parsing by replacing == markers with placeholders.
  /// This allows nested formatting like ==**bold**== to be parsed correctly by cmark.
  /// Returns the modified string and whether any replacements were made.
  public func protectingHighlightMarkers() -> (result: String, hasHighlights: Bool) {
    // Pattern matches ==content== where content is non-empty and doesn't span multiple lines
    // Using non-greedy match to find the closest ==
    let pattern = #"==([^=\n]+?)==(?!=)"#

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
            let contentRange = Range(match.range(at: 1), in: result) else { continue }

      let content = String(result[contentRange])
      let replacement = "\(highlightOpenPlaceholder)\(content)\(highlightClosePlaceholder)"

      result.replaceSubrange(fullRange, with: replacement)
      hasReplacements = true
    }

    return (result, hasReplacements)
  }

  /// Protects inline math syntax ($...$) from cmark parsing by replacing $ markers with placeholders.
  /// This prevents cmark from treating dollar signs as regular text and allows proper math detection.
  /// Returns the modified string and whether any replacements were made.
  ///
  /// Note: This only matches single $ delimiters (inline math), not $$ (display math).
  public func protectingInlineMathMarkers() -> (result: String, hasInlineMath: Bool) {
    // Pattern matches $content$ where:
    // - Not preceded by $ (avoids $$)
    // - Content is non-empty and doesn't contain $ or newlines
    // - Not followed by $ (avoids $$)
    // Using negative lookbehind/lookahead for $$ detection
    let pattern = #"(?<!\$)\$([^$\n]+?)\$(?!\$)"#

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
            let contentRange = Range(match.range(at: 1), in: result) else { continue }

      let content = String(result[contentRange])
      let replacement = "\(mathOpenPlaceholder)\(content)\(mathClosePlaceholder)"

      result.replaceSubrange(fullRange, with: replacement)
      hasReplacements = true
    }

    return (result, hasReplacements)
  }

  /// Protects image dimension syntax from the table parser by replacing | with a placeholder.
  /// Returns the modified string and whether any replacements were made.
  ///
  /// Matches patterns like: ![alt|100](url) or ![alt|100x200](url)
  public func protectingImageDimensions() -> (result: String, hasImageDimensions: Bool) {
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

public extension Array where Element == BlockNode {
  /// Restores image dimension placeholders back to | characters.
  public func restoringImageDimensions() -> [BlockNode] {
    self.map { block in
      block.restoringImageDimensions()
    }
  }
}

public extension BlockNode {
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

public extension Array where Element == InlineNode {
  /// Restores image dimension placeholders in inline nodes.
  fileprivate func restoringImageDimensions() -> [InlineNode] {
    self.map { $0.restoringImageDimensions() }
  }
}

public extension InlineNode {
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

public extension Array where Element == InlineNode {
  /// Restores highlight placeholders back into proper .highlight nodes.
  /// This handles nested formatting correctly by collecting all nodes between open/close markers.
  public func restoringHighlightMarkers() -> [InlineNode] {
    var results: [InlineNode] = []
    var highlightBuffer: [InlineNode]? = nil  // nil means not in highlight, [] means collecting
    var i = 0

    while i < self.count {
      let node = self[i]

      switch node {
      case .text(let content):
        // Check for highlight markers in the text
        let processed = processTextForHighlightMarkers(
          content,
          highlightBuffer: &highlightBuffer,
          results: &results
        )
        results.append(contentsOf: processed)

      case .emphasis(let children):
        let processed = InlineNode.emphasis(children: children.restoringHighlightMarkers())
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      case .strong(let children):
        let processed = InlineNode.strong(children: children.restoringHighlightMarkers())
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      case .strikethrough(let children):
        let processed = InlineNode.strikethrough(children: children.restoringHighlightMarkers())
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      case .highlight(let children):
        let processed = InlineNode.highlight(children: children.restoringHighlightMarkers())
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      case .link(let destination, let children):
        let processed = InlineNode.link(
          destination: destination,
          children: children.restoringHighlightMarkers()
        )
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      case .image(let source, let children):
        let processed = InlineNode.image(source: source, children: children.restoringHighlightMarkers())
        if highlightBuffer != nil {
          highlightBuffer?.append(processed)
        } else {
          results.append(processed)
        }

      default:
        if highlightBuffer != nil {
          highlightBuffer?.append(node)
        } else {
          results.append(node)
        }
      }

      i += 1
    }

    // If we ended while still in a highlight (unclosed), just add the buffer as regular content
    if let remaining = highlightBuffer, !remaining.isEmpty {
      results.append(contentsOf: remaining)
    }

    return results
  }
}

/// Processes a text node for highlight placeholders.
/// Handles cases where markers and content are in the same text node.
private func processTextForHighlightMarkers(
  _ text: String,
  highlightBuffer: inout [InlineNode]?,
  results: inout [InlineNode]
) -> [InlineNode] {
  var output: [InlineNode] = []
  var current = text.startIndex

  while current < text.endIndex {
    if highlightBuffer == nil {
      // Not in highlight mode - look for open marker
      if let openRange = text.range(
        of: highlightOpenPlaceholder,
        range: current..<text.endIndex
      ) {
        // Add text before the marker
        if current < openRange.lowerBound {
          let before = String(text[current..<openRange.lowerBound])
          output.append(.text(before))
        }

        // Start collecting highlight content
        highlightBuffer = []
        current = openRange.upperBound

        // Check if there's a close marker in the same text node
        if let closeRange = text.range(
          of: highlightClosePlaceholder,
          range: current..<text.endIndex
        ) {
          // Content between markers in same text node
          let content = String(text[current..<closeRange.lowerBound])
          if !content.isEmpty {
            highlightBuffer?.append(.text(content))
          }

          // Close the highlight
          if let buffer = highlightBuffer {
            output.append(.highlight(children: buffer))
          }
          highlightBuffer = nil
          current = closeRange.upperBound
        }
        // else: close marker is in a later node, continue collecting
      } else {
        // No open marker found - add remaining text
        let remaining = String(text[current...])
        if !remaining.isEmpty {
          output.append(.text(remaining))
        }
        current = text.endIndex
      }
    } else {
      // In highlight mode - look for close marker
      if let closeRange = text.range(
        of: highlightClosePlaceholder,
        range: current..<text.endIndex
      ) {
        // Add text before the close marker to highlight buffer
        if current < closeRange.lowerBound {
          let content = String(text[current..<closeRange.lowerBound])
          highlightBuffer?.append(.text(content))
        }

        // Close the highlight and add to results (not output, since we're collecting)
        if let buffer = highlightBuffer {
          results.append(.highlight(children: buffer))
        }
        highlightBuffer = nil
        current = closeRange.upperBound

        // Continue looking for more markers after this close
      } else {
        // No close marker - add all remaining text to buffer
        let remaining = String(text[current...])
        if !remaining.isEmpty {
          highlightBuffer?.append(.text(remaining))
        }
        current = text.endIndex
      }
    }
  }

  return output
}

// MARK: - Inline Math Syntax ($...$)

public extension Array where Element == InlineNode {
  /// Restores math placeholders back into proper .math nodes.
  /// Math content is a leaf node (like .code), so doesn't support nested formatting.
  public func restoringMathMarkers() -> [InlineNode] {
    self.flatMap { node -> [InlineNode] in
      switch node {
      case .text(let content):
        return processTextForMathMarkers(content)

      case .emphasis(let children):
        return [.emphasis(children: children.restoringMathMarkers())]

      case .strong(let children):
        return [.strong(children: children.restoringMathMarkers())]

      case .strikethrough(let children):
        return [.strikethrough(children: children.restoringMathMarkers())]

      case .highlight(let children):
        return [.highlight(children: children.restoringMathMarkers())]

      case .link(let destination, let children):
        return [.link(destination: destination, children: children.restoringMathMarkers())]

      case .image(let source, let children):
        return [.image(source: source, children: children.restoringMathMarkers())]

      default:
        return [node]
      }
    }
  }
}

/// Processes a text node for math placeholders and returns the resulting inline nodes.
private func processTextForMathMarkers(_ text: String) -> [InlineNode] {
  var results: [InlineNode] = []
  var current = text.startIndex

  while current < text.endIndex {
    // Look for math open marker
    if let openRange = text.range(of: mathOpenPlaceholder, range: current..<text.endIndex) {
      // Add text before the marker
      if current < openRange.lowerBound {
        let before = String(text[current..<openRange.lowerBound])
        results.append(.text(before))
      }

      // Look for the close marker
      let searchStart = openRange.upperBound
      if let closeRange = text.range(of: mathClosePlaceholder, range: searchStart..<text.endIndex) {
        // Extract math content
        let mathContent = String(text[searchStart..<closeRange.lowerBound])
        print("[MathParsing] Created .math node: '\(mathContent)'")
        results.append(.math(mathContent))
        current = closeRange.upperBound
      } else {
        // No close marker found - treat open marker as text and continue
        results.append(.text(mathOpenPlaceholder))
        current = openRange.upperBound
      }
    } else {
      // No more math markers - add remaining text
      let remaining = String(text[current...])
      if !remaining.isEmpty {
        results.append(.text(remaining))
      }
      current = text.endIndex
    }
  }

  return results
}

// MARK: - Callout Syntax (> [!type])

public extension Array where Element == BlockNode {
  /// Rewrites blockquotes that start with [!type] into .callout nodes.
  public func applyCalloutSyntax() -> [BlockNode] {
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
  // Use proper NSRange to String.Index conversion to handle complex Unicode (Thai, etc.)
  guard let matchRange = Range(match.range, in: text) else { return nil }
  let remainingFirstLineText = String(text[matchRange.upperBound...]).trimmingCharacters(in: .whitespaces)

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

public extension Array where Element == BlockNode {
  /// Applies all Obsidian markdown extensions (callouts, highlights, and inline math).
  public func applyObsidianExtensions() -> [BlockNode] {
    self
      .applyCalloutSyntax()
      .restoringInlineMarkersInBlocks()
  }

  /// Restores highlight and math markers in all inline content within blocks.
  private func restoringInlineMarkersInBlocks() -> [BlockNode] {
    self.map { block -> BlockNode in
      switch block {
      case .blockquote(let children):
        return .blockquote(children: children.restoringInlineMarkersInBlocks())

      case .callout(let type, let title, let children):
        return .callout(type: type, title: title, children: children.restoringInlineMarkersInBlocks())

      case .bulletedList(let isTight, let items):
        return .bulletedList(
          isTight: isTight,
          items: items.map { RawListItem(children: $0.children.restoringInlineMarkersInBlocks()) }
        )

      case .numberedList(let isTight, let start, let items):
        return .numberedList(
          isTight: isTight,
          start: start,
          items: items.map { RawListItem(children: $0.children.restoringInlineMarkersInBlocks()) }
        )

      case .taskList(let isTight, let items):
        return .taskList(
          isTight: isTight,
          items: items.map {
            RawTaskListItem(isCompleted: $0.isCompleted, children: $0.children.restoringInlineMarkersInBlocks())
          }
        )

      case .paragraph(let content):
        return .paragraph(content: content.restoringHighlightMarkers().restoringMathMarkers())

      case .heading(let level, let content):
        return .heading(level: level, content: content.restoringHighlightMarkers().restoringMathMarkers())

      case .table(let columnAlignments, let rows):
        return .table(
          columnAlignments: columnAlignments,
          rows: rows.map { row in
            RawTableRow(cells: row.cells.map { cell in
              RawTableCell(content: cell.content.restoringHighlightMarkers().restoringMathMarkers())
            })
          }
        )

      default:
        return block
      }
    }
  }
}
