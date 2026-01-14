import SwiftUI
import MarkdownUICore

struct CodeBlockView: View {
  @Environment(\.theme.codeBlock) private var codeBlock
  @Environment(\.codeSyntaxHighlighter) private var codeSyntaxHighlighter
  @Environment(\.codeBlockProvider) private var codeBlockProvider

  private let fenceInfo: String?
  private let content: String

  init(fenceInfo: String?, content: String) {
    self.fenceInfo = fenceInfo
    self.content = content.hasSuffix("\n") ? String(content.dropLast()) : content
  }

  var body: some View {
    // Check if a custom code block provider wants to handle this block
    if let customView = codeBlockProvider.makeBody(language: fenceInfo, content: content) {
      customView
    } else {
      // Fall back to default code block rendering with syntax highlighting
      self.codeBlock.makeBody(
        configuration: .init(
          language: self.fenceInfo,
          content: self.content,
          label: .init(self.label)
        )
      )
    }
  }

  private var label: some View {
    self.codeSyntaxHighlighter.highlightCode(self.content, language: self.fenceInfo)
      .textStyleFont()
      .textStyleForegroundColor()
  }
}
