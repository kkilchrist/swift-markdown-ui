import SwiftUI
import MarkdownUICore

struct InlineText: View {
  @Environment(\.inlineImageProvider) private var inlineImageProvider
  @Environment(\.inlineMathProvider) private var inlineMathProvider
  @Environment(\.baseURL) private var baseURL
  @Environment(\.imageBaseURL) private var imageBaseURL
  @Environment(\.softBreakMode) private var softBreakMode
  @Environment(\.theme) private var theme

  @State private var inlineImages: [String: Image] = [:]
  @State private var mathImages: [String: Image] = [:]

  private let inlines: [InlineNode]

  init(_ inlines: [InlineNode]) {
    self.inlines = inlines
  }

  var body: some View {
    TextStyleAttributesReader { attributes in
      if self.softBreakMode == .lineBreak,
         let spacing = self.theme.softBreak.spacing,
         self.hasLineBreaks {
        self.renderWithLineBreakSpacing(
          attributes: attributes,
          spacing: spacing.points(relativeTo: attributes.fontProperties)
        )
      } else {
        self.renderText(attributes: attributes)
      }
    }
    .task(id: self.inlines) {
      self.inlineImages = (try? await self.loadInlineImages()) ?? [:]
      self.mathImages = await self.loadMathImages()
    }
  }

  private var hasLineBreaks: Bool {
    self.inlines.contains { $0 == .softBreak || $0 == .lineBreak }
  }

  @ViewBuilder
  private func renderWithLineBreakSpacing(attributes: AttributeContainer, spacing: CGFloat) -> some View {
    let segments = self.splitAtLineBreaks()
    VStack(alignment: .leading, spacing: spacing) {
      ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
        self.renderSegment(segment, attributes: attributes)
      }
    }
  }

  private func splitAtLineBreaks() -> [[InlineNode]] {
    var segments: [[InlineNode]] = []
    var currentSegment: [InlineNode] = []

    for inline in self.inlines {
      if inline == .softBreak || inline == .lineBreak {
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
      mathImages: self.mathImages,
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
      mathImages: self.mathImages,
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

  private func loadMathImages() async -> [String: Image] {
    // Extract unique math expressions from inlines
    let mathExpressions = Set(self.inlines.compactMap(\.mathContent))
    guard !mathExpressions.isEmpty else { return [:] }

    return await withTaskGroup(of: (String, Image?).self) { taskGroup in
      for math in mathExpressions {
        taskGroup.addTask {
          do {
            let image = try await self.inlineMathProvider.image(for: math)
            return (math, image)
          } catch {
            // Provider threw (e.g., default provider) - fall back to text rendering
            return (math, nil)
          }
        }
      }

      var mathImages: [String: Image] = [:]

      for await result in taskGroup {
        if let image = result.1 {
          mathImages[result.0] = image
        }
      }

      return mathImages
    }
  }
}
