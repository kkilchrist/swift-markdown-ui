import SwiftUI
import MarkdownUICore

struct CalloutView: View {
  @Environment(\.theme.callout) private var callout

  private let type: String
  private let title: String?
  private let children: [BlockNode]

  init(type: String, title: String?, children: [BlockNode]) {
    self.type = type
    self.title = title
    self.children = children
  }

  var body: some View {
    self.callout.makeBody(
      configuration: .init(
        type: self.type,
        title: self.title,
        label: .init(BlockSequence(self.children)),
        content: .init(block: .callout(type: self.type, title: self.title, children: self.children))
      )
    )
  }
}
