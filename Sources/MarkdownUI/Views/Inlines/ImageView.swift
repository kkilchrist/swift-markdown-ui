import SwiftUI

struct ImageView: View {
  @Environment(\.theme.image) private var image
  @Environment(\.imageProvider) private var imageProvider
  @Environment(\.imageBaseURL) private var baseURL

  private let data: RawImageData

  init(data: RawImageData) {
    self.data = data
  }

  var body: some View {
    self.image.makeBody(
      configuration: .init(
        label: .init(self.label),
        content: .init(block: self.content)
      )
    )
  }

  private var label: some View {
    self.imageProvider.makeImage(url: self.url)
      .imageConstraints(maxWidth: self.data.maxWidth, maxHeight: self.data.maxHeight)
      .link(destination: self.data.destination)
      .accessibilityLabel(self.data.alt)
  }

  private var content: BlockNode {
    if let destination = self.data.destination {
      return .paragraph(
        content: [
          .link(
            destination: destination,
            children: [.image(source: self.data.source, children: [.text(self.data.alt)])]
          )
        ]
      )
    } else {
      return .paragraph(
        content: [.image(source: self.data.source, children: [.text(self.data.alt)])]
      )
    }
  }

  private var url: URL? {
    URL(string: self.data.source, relativeTo: self.baseURL)
  }
}

extension ImageView {
  init?(_ inlines: [InlineNode]) {
    guard inlines.count == 1, let data = inlines.first?.imageData else {
      return nil
    }
    self.init(data: data)
  }
}

extension View {
  fileprivate func link(destination: String?) -> some View {
    self.modifier(LinkModifier(destination: destination))
  }

  @ViewBuilder
  fileprivate func imageConstraints(maxWidth: CGFloat?, maxHeight: CGFloat?) -> some View {
    if maxWidth != nil || maxHeight != nil {
      ImageConstraintContainer(maxWidth: maxWidth, maxHeight: maxHeight) {
        self
      }
    } else {
      self
    }
  }
}

/// A container that enforces max width/height constraints on its content
private struct ImageConstraintContainer<Content: View>: View {
  let maxWidth: CGFloat?
  let maxHeight: CGFloat?
  let content: Content

  init(maxWidth: CGFloat?, maxHeight: CGFloat?, @ViewBuilder content: () -> Content) {
    self.maxWidth = maxWidth
    self.maxHeight = maxHeight
    self.content = content()
  }

  var body: some View {
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      ConstrainedImageLayout(maxWidth: maxWidth, maxHeight: maxHeight) {
        content
      }
    } else {
      // Fallback for older OS - use GeometryReader approach
      GeometryReader { proxy in
        let constrainedWidth = maxWidth.map { min($0, proxy.size.width) } ?? proxy.size.width
        content
          .frame(maxWidth: constrainedWidth, maxHeight: maxHeight)
      }
      .frame(maxWidth: maxWidth, maxHeight: maxHeight)
    }
  }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
private struct ConstrainedImageLayout: Layout {
  let maxWidth: CGFloat?
  let maxHeight: CGFloat?

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    guard let view = subviews.first else { return .zero }

    // Constrain the proposal before passing to child
    let constrainedWidth = min(proposal.width ?? .infinity, maxWidth ?? .infinity)
    let constrainedHeight = min(proposal.height ?? .infinity, maxHeight ?? .infinity)
    let constrainedProposal = ProposedViewSize(width: constrainedWidth, height: constrainedHeight)

    var size = view.sizeThatFits(constrainedProposal)

    // Also clamp the result
    if let maxWidth, size.width > maxWidth {
      size.width = maxWidth
    }
    if let maxHeight, size.height > maxHeight {
      size.height = maxHeight
    }

    return size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    guard let view = subviews.first else { return }
    view.place(at: bounds.origin, proposal: .init(bounds.size))
  }
}

private struct LinkModifier: ViewModifier {
  @Environment(\.baseURL) private var baseURL
  @Environment(\.openURL) private var openURL

  let destination: String?

  var url: URL? {
    self.destination.flatMap {
      URL(string: $0, relativeTo: self.baseURL)
    }
  }

  func body(content: Content) -> some View {
    if let url {
      Button {
        self.openURL(url)
      } label: {
        content
      }
      .buttonStyle(.plain)
    } else {
      content
    }
  }
}
