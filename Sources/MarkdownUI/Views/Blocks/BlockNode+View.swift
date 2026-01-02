import SwiftUI
import MarkdownUICore

extension BlockNode: View {
  public var body: some View {
    DirectionalBlockView(block: self)
  }
}

/// A wrapper view that applies the correct layout direction to a block based on its content.
private struct DirectionalBlockView: View {
  @Environment(\.markdownTextDirectionMode) private var directionMode

  let block: BlockNode

  var body: some View {
    blockContent
      .environment(\.layoutDirection, resolvedLayoutDirection)
  }

  private var resolvedLayoutDirection: LayoutDirection {
    switch directionMode {
    case .automatic:
      return block.textDirection == .rightToLeft ? .rightToLeft : .leftToRight
    case .leftToRight:
      return .leftToRight
    case .rightToLeft:
      return .rightToLeft
    }
  }

  @ViewBuilder
  private var blockContent: some View {
    switch block {
    case .blockquote(let children):
      BlockquoteView(children: children)
    case .callout(let type, let title, let children):
      CalloutView(type: type, title: title, children: children)
    case .bulletedList(let isTight, let items):
      BulletedListView(isTight: isTight, items: items)
    case .numberedList(let isTight, let start, let items):
      NumberedListView(isTight: isTight, start: start, items: items)
    case .taskList(let isTight, let items):
      TaskListView(isTight: isTight, items: items)
    case .codeBlock(let fenceInfo, let content):
      CodeBlockView(fenceInfo: fenceInfo, content: content)
    case .htmlBlock(let content):
      ParagraphView(content: content)
    case .paragraph(let content):
      ParagraphView(content: content)
    case .heading(let level, let content):
      HeadingView(level: level, content: content)
    case .table(let columnAlignments, let rows):
      if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
        TableView(columnAlignments: columnAlignments, rows: rows)
      }
    case .thematicBreak:
      ThematicBreakView()
    }
  }
}
