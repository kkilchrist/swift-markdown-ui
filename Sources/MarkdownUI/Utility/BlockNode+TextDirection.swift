import Foundation

extension BlockNode {
  /// Detects the text direction for this block based on its content.
  ///
  /// Uses the Unicode Bidirectional Algorithm to find the first strong
  /// directional character in the block's text content.
  var textDirection: TextDirection {
    TextDirection.detect(from: self.plainTextContent)
  }

  /// Returns the plain text content of this block for direction detection.
  private var plainTextContent: String {
    switch self {
    case .paragraph(let content):
      return content.renderPlainText()
    case .heading(_, let content):
      return content.renderPlainText()
    case .blockquote(let children):
      return children.map(\.plainTextContent).joined(separator: " ")
    case .callout(_, _, let children):
      return children.map(\.plainTextContent).joined(separator: " ")
    case .bulletedList(_, let items):
      return items.flatMap(\.children).map(\.plainTextContent).joined(separator: " ")
    case .numberedList(_, _, let items):
      return items.flatMap(\.children).map(\.plainTextContent).joined(separator: " ")
    case .taskList(_, let items):
      return items.flatMap(\.children).map(\.plainTextContent).joined(separator: " ")
    case .codeBlock(_, let content):
      return content
    case .htmlBlock(let content):
      return content
    case .table(_, let rows):
      return rows.flatMap(\.cells).map { $0.content.renderPlainText() }.joined(separator: " ")
    case .thematicBreak:
      return ""
    }
  }
}
