import SwiftUI

struct InlineText: View {
  @Environment(\.inlineImageProvider) private var inlineImageProvider
  @Environment(\.baseURL) private var baseURL
  @Environment(\.imageBaseURL) private var imageBaseURL
  @Environment(\.softBreakMode) private var softBreakMode
  @Environment(\.theme) private var theme

  @State private var inlineImages: [String: Image] = [:]

  private let inlines: [InlineNode]

  init(_ inlines: [InlineNode]) {
    self.inlines = inlines
  }

  var body: some View {
    TextStyleAttributesReader { attributes in
      let _ = Self.debugSoftBreak(
        mode: self.softBreakMode,
        spacing: self.theme.softBreak.spacing,
        hasSoftBreaks: self.hasSoftBreaks,
        inlines: self.inlines
      )
      if self.softBreakMode == .lineBreak,
         let spacing = self.theme.softBreak.spacing,
         self.hasSoftBreaks {
        self.renderWithSoftBreakSpacing(
          attributes: attributes,
          spacing: spacing.points(relativeTo: attributes.fontProperties)
        )
      } else {
        self.renderText(attributes: attributes)
      }
    }
    .task(id: self.inlines) {
      self.inlineImages = (try? await self.loadInlineImages()) ?? [:]
    }
  }

  private static func debugSoftBreak(
    mode: SoftBreak.Mode,
    spacing: RelativeSize?,
    hasSoftBreaks: Bool,
    inlines: [InlineNode]
  ) {
    #if DEBUG
    if hasSoftBreaks || spacing != nil {
      print("[SoftBreak Debug] mode=\(mode), spacing=\(String(describing: spacing)), hasSoftBreaks=\(hasSoftBreaks)")
      print("[SoftBreak Debug] inlines=\(inlines)")
    }
    #endif
  }

  private var hasSoftBreaks: Bool {
    self.inlines.contains { $0 == .softBreak }
  }

  @ViewBuilder
  private func renderWithSoftBreakSpacing(attributes: AttributeContainer, spacing: CGFloat) -> some View {
    let segments = self.splitAtSoftBreaks()
    VStack(alignment: .leading, spacing: spacing) {
      ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
        self.renderSegment(segment, attributes: attributes)
      }
    }
  }

  private func splitAtSoftBreaks() -> [[InlineNode]] {
    var segments: [[InlineNode]] = []
    var currentSegment: [InlineNode] = []

    for inline in self.inlines {
      if inline == .softBreak {
        if !currentSegment.isEmpty {
          segments.append(currentSegment)
          currentSegment = []
        }
      } else {
        currentSegment.append(inline)
      }
    }

    if !currentSegment.isEmpty {
      segments.append(currentSegment)
    }

    return segments
  }

  private func renderSegment(_ segment: [InlineNode], attributes: AttributeContainer) -> Text {
    segment.renderText(
      baseURL: self.baseURL,
      textStyles: self.textStyles,
      images: self.inlineImages,
      softBreakMode: self.softBreakMode,
      attributes: attributes,
      fontProperties: attributes.fontProperties
    )
  }

  private func renderText(attributes: AttributeContainer) -> Text {
    self.inlines.renderText(
      baseURL: self.baseURL,
      textStyles: self.textStyles,
      images: self.inlineImages,
      softBreakMode: self.softBreakMode,
      attributes: attributes,
      fontProperties: attributes.fontProperties
    )
  }

  private var textStyles: InlineTextStyles {
    .init(
      code: self.theme.code,
      emphasis: self.theme.emphasis,
      strong: self.theme.strong,
      strikethrough: self.theme.strikethrough,
      highlight: self.theme.highlight,
      link: self.theme.link,
      softBreak: self.theme.softBreak
    )
  }

  private func loadInlineImages() async throws -> [String: Image] {
    let images = Set(self.inlines.compactMap(\.imageData))
    guard !images.isEmpty else { return [:] }

    return try await withThrowingTaskGroup(of: (String, Image).self) { taskGroup in
      for image in images {
        guard let url = URL(string: image.source, relativeTo: self.imageBaseURL) else {
          continue
        }

        taskGroup.addTask {
          (image.source, try await self.inlineImageProvider.image(with: url, label: image.alt))
        }
      }

      var inlineImages: [String: Image] = [:]

      for try await result in taskGroup {
        inlineImages[result.0] = result.1
      }

      return inlineImages
    }
  }
}
