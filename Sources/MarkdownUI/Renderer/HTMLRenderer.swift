import Foundation

// MARK: - Block Node HTML Rendering

extension Array where Element == BlockNode {
  /// Renders the blocks as HTML with full support for extended markdown syntax.
  func renderExtendedHTML() -> String {
    self.map { $0.renderExtendedHTML() }.joined(separator: "\n")
  }
}

extension BlockNode {
  /// Returns the HTML `dir` attribute for this block based on text direction.
  private var htmlDirAttribute: String {
    textDirection == .rightToLeft ? " dir=\"rtl\"" : ""
  }

  /// Renders this block as HTML with full support for extended markdown syntax.
  func renderExtendedHTML() -> String {
    switch self {
    case .blockquote(let children):
      let content = children.map { $0.renderExtendedHTML() }.joined(separator: "\n")
      return "<blockquote\(htmlDirAttribute)>\n\(content)\n</blockquote>"

    case .callout(let type, let title, let children):
      let calloutType = CalloutType(rawValue: type)
      let color = calloutType?.color.cssValue ?? "#6b7280"
      let icon = calloutType?.htmlIcon ?? "ℹ️"
      let displayTitle = title ?? type.capitalized
      let content = children.map { $0.renderExtendedHTML() }.joined(separator: "\n")

      return """
        <div class="callout callout-\(type)"\(htmlDirAttribute) style="--callout-color: \(color);">
          <div class="callout-header">
            <span class="callout-icon">\(icon)</span>
            <span class="callout-title">\(displayTitle.htmlEscaped)</span>
          </div>
          <div class="callout-content">
            \(content)
          </div>
        </div>
        """

    case .bulletedList(let isTight, let items):
      let listItems = items.map { item -> String in
        let content = isTight
          ? item.children.compactMap { $0.tightListItemHTML() }.joined()
          : item.children.map { $0.renderExtendedHTML() }.joined(separator: "\n")
        return "<li>\(content)</li>"
      }.joined(separator: "\n")
      return "<ul\(htmlDirAttribute)>\n\(listItems)\n</ul>"

    case .numberedList(let isTight, let start, let items):
      let startAttr = start != 1 ? " start=\"\(start)\"" : ""
      let listItems = items.map { item -> String in
        let content = isTight
          ? item.children.compactMap { $0.tightListItemHTML() }.joined()
          : item.children.map { $0.renderExtendedHTML() }.joined(separator: "\n")
        return "<li>\(content)</li>"
      }.joined(separator: "\n")
      return "<ol\(startAttr)\(htmlDirAttribute)>\n\(listItems)\n</ol>"

    case .taskList(let isTight, let items):
      let listItems = items.map { item -> String in
        let checkbox = item.isCompleted
          ? "<input type=\"checkbox\" checked disabled>"
          : "<input type=\"checkbox\" disabled>"
        let content = isTight
          ? item.children.compactMap { $0.tightListItemHTML() }.joined()
          : item.children.map { $0.renderExtendedHTML() }.joined(separator: "\n")
        return "<li class=\"task-list-item\">\(checkbox) \(content)</li>"
      }.joined(separator: "\n")
      return "<ul class=\"task-list\"\(htmlDirAttribute)>\n\(listItems)\n</ul>"

    case .codeBlock(let fenceInfo, let content):
      let languageClass = fenceInfo.map { " class=\"language-\($0)\"" } ?? ""
      let escapedContent = content.htmlEscaped
      return "<pre><code\(languageClass)>\(escapedContent)</code></pre>"

    case .htmlBlock(let content):
      return content

    case .paragraph(let content):
      let inlineHTML = content.renderExtendedHTML()
      return "<p\(htmlDirAttribute)>\(inlineHTML)</p>"

    case .heading(let level, let content):
      let tag = "h\(min(max(level, 1), 6))"
      let inlineHTML = content.renderExtendedHTML()
      let id = content.renderPlainText().kebabCased()
      return "<\(tag) id=\"\(id)\"\(htmlDirAttribute)>\(inlineHTML)</\(tag)>"

    case .table(let columnAlignments, let rows):
      guard !rows.isEmpty else { return "" }

      var html = "<table\(htmlDirAttribute)>\n"

      // Header row
      if let headerRow = rows.first {
        html += "<thead>\n<tr>\n"
        for (index, cell) in headerRow.cells.enumerated() {
          let align = index < columnAlignments.count ? columnAlignments[index] : .none
          let alignAttr = align.htmlAttribute
          let cellContent = cell.content.renderExtendedHTML()
          html += "<th\(alignAttr)>\(cellContent)</th>\n"
        }
        html += "</tr>\n</thead>\n"
      }

      // Body rows
      if rows.count > 1 {
        html += "<tbody>\n"
        for row in rows.dropFirst() {
          html += "<tr>\n"
          for (index, cell) in row.cells.enumerated() {
            let align = index < columnAlignments.count ? columnAlignments[index] : .none
            let alignAttr = align.htmlAttribute
            let cellContent = cell.content.renderExtendedHTML()
            html += "<td\(alignAttr)>\(cellContent)</td>\n"
          }
          html += "</tr>\n"
        }
        html += "</tbody>\n"
      }

      html += "</table>"
      return html

    case .thematicBreak:
      return "<hr>"
    }
  }

  /// Renders a block for tight list items (paragraphs become inline).
  fileprivate func tightListItemHTML() -> String? {
    switch self {
    case .paragraph(let content):
      return content.renderExtendedHTML()
    default:
      return self.renderExtendedHTML()
    }
  }
}

// MARK: - Inline Node HTML Rendering

extension Array where Element == InlineNode {
  /// Renders the inline nodes as HTML with full support for extended markdown syntax.
  func renderExtendedHTML() -> String {
    self.map { $0.renderExtendedHTML() }.joined()
  }

  fileprivate func renderPlainTextForHTML() -> String {
    self.map { $0.renderPlainText() }.joined()
  }
}

extension InlineNode {
  /// Renders this inline node as HTML with full support for extended markdown syntax.
  public func renderExtendedHTML() -> String {
    switch self {
    case .text(let content):
      return content.htmlEscaped

    case .softBreak:
      return "\n"

    case .lineBreak:
      return "<br>\n"

    case .code(let content):
      return "<code>\(content.htmlEscaped)</code>"

    case .html(let content):
      return content

    case .emphasis(let children):
      return "<em>\(children.renderExtendedHTML())</em>"

    case .strong(let children):
      return "<strong>\(children.renderExtendedHTML())</strong>"

    case .strikethrough(let children):
      return "<del>\(children.renderExtendedHTML())</del>"

    case .highlight(let children):
      return "<mark>\(children.renderExtendedHTML())</mark>"

    case .link(let destination, let children):
      let escapedDest = destination.htmlEscaped
      return "<a href=\"\(escapedDest)\">\(children.renderExtendedHTML())</a>"

    case .image(let source, let children):
      let fullAlt = children.renderPlainText()
      let (cleanAlt, maxWidth, maxHeight) = parseHTMLImageDimensions(from: fullAlt)
      let escapedSrc = source.htmlEscaped

      var styleAttr = ""
      if let maxWidth, let maxHeight {
        styleAttr = " style=\"max-width: \(Int(maxWidth))px; max-height: \(Int(maxHeight))px; object-fit: contain;\""
      } else if let maxWidth {
        styleAttr = " style=\"max-width: \(Int(maxWidth))px; height: auto;\""
      } else if let maxHeight {
        styleAttr = " style=\"width: auto; max-height: \(Int(maxHeight))px;\""
      }

      return "<img src=\"\(escapedSrc)\" alt=\"\(cleanAlt.htmlEscaped)\"\(styleAttr)>"
    }
  }

  fileprivate func renderPlainText() -> String {
    switch self {
    case .text(let content):
      return content
    case .softBreak, .lineBreak:
      return " "
    case .code(let content):
      return content
    case .html:
      return ""
    case .emphasis(let children), .strong(let children), .strikethrough(let children),
         .highlight(let children), .link(_, let children), .image(_, let children):
      return children.renderPlainText()
    }
  }
}

// MARK: - Table Alignment Helper

extension RawTableColumnAlignment {
  fileprivate var htmlAttribute: String {
    switch self {
    case .left:
      return " style=\"text-align: left;\""
    case .center:
      return " style=\"text-align: center;\""
    case .right:
      return " style=\"text-align: right;\""
    case .none:
      return ""
    }
  }
}

// MARK: - String HTML Helpers

extension String {
  fileprivate var htmlEscaped: String {
    self
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }
}

// MARK: - Image Dimension Parsing

/// Parses Obsidian-style image dimensions from alt text for HTML rendering.
private func parseHTMLImageDimensions(from altText: String) -> (cleanAlt: String, maxWidth: Int?, maxHeight: Int?) {
  let pattern = #"^(.*?)\|(\d+)(?:x(\d+))?$"#

  guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
    return (altText, nil, nil)
  }

  let nsRange = NSRange(altText.startIndex..., in: altText)
  guard let match = regex.firstMatch(in: altText, options: [], range: nsRange) else {
    return (altText, nil, nil)
  }

  let cleanAlt: String
  if let range = Range(match.range(at: 1), in: altText) {
    cleanAlt = String(altText[range])
  } else {
    cleanAlt = ""
  }

  var width: Int? = nil
  if let range = Range(match.range(at: 2), in: altText) {
    width = Int(altText[range])
  }

  var height: Int? = nil
  if match.range(at: 3).location != NSNotFound,
     let range = Range(match.range(at: 3), in: altText) {
    height = Int(altText[range])
  }

  return (cleanAlt, width, height)
}

// MARK: - Color CSS Helper

import SwiftUI

extension Color {
  fileprivate var cssValue: String {
    switch self {
    case .blue: return "#3b82f6"
    case .cyan: return "#06b6d4"
    case .green: return "#22c55e"
    case .orange: return "#f97316"
    case .red: return "#ef4444"
    case .purple: return "#a855f7"
    case .gray: return "#6b7280"
    default: return "#6b7280"
    }
  }
}
