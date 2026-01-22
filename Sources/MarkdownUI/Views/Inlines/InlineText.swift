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
  @State private var asyncLoadedMath: [String: RenderedMath] = [:]

  private let inlines: [InlineNode]

  /// Computed property that merges cache (synchronous) with async-loaded math.
  /// This ensures cached math is available immediately during body evaluation,
  /// preventing flashing when the view re-renders.
  private var renderedMath: [String: RenderedMath] {
    var results = loadCachedMath()  // Check cache synchronously
    results.merge(asyncLoadedMath) { _, asyncLoaded in asyncLoaded }
    return results
  }

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
      // Load any uncached math asynchronously (cached math is handled by computed property)
      let uncachedMath = await self.loadUncachedRenderedMath()
      if !uncachedMath.isEmpty {
        self.asyncLoadedMath.merge(uncachedMath) { _, new in new }
      }
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
      renderedMath: self.renderedMath,
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
      renderedMath: self.renderedMath,
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
      softBreak: self.theme.softBreak,
      criticAddition: self.theme.criticAddition,
      criticDeletion: self.theme.criticDeletion,
      criticSubstitutionOld: self.theme.criticSubstitutionOld,
      criticSubstitutionNew: self.theme.criticSubstitutionNew,
      criticComment: self.theme.criticComment,
      criticHighlight: self.theme.criticHighlight
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

  /// Synchronously load math from cache - returns immediately with cached values
  private func loadCachedMath() -> [String: RenderedMath] {
    let mathExpressions = Set(self.inlines.compactMap(\.mathContent))
    guard !mathExpressions.isEmpty else { return [:] }

    var results: [String: RenderedMath] = [:]
    for math in mathExpressions {
      if let cached = self.inlineMathProvider.cachedRenderedMath(for: math) {
        results[math] = cached
      }
    }
    return results
  }

  /// Asynchronously load only math that isn't already cached
  private func loadUncachedRenderedMath() async -> [String: RenderedMath] {
    // Extract unique math expressions from inlines
    let mathExpressions = Set(self.inlines.compactMap(\.mathContent))
    guard !mathExpressions.isEmpty else { return [:] }

    // Filter to only uncached expressions
    let uncachedExpressions = mathExpressions.filter {
      self.inlineMathProvider.cachedRenderedMath(for: $0) == nil
    }
    guard !uncachedExpressions.isEmpty else { return [:] }

    return await withTaskGroup(of: (String, RenderedMath?).self) { taskGroup in
      for math in uncachedExpressions {
        taskGroup.addTask {
          do {
            let rendered = try await self.inlineMathProvider.renderedMath(for: math)
            return (math, rendered)
          } catch {
            // Provider threw (e.g., default provider) - fall back to text rendering
            return (math, nil)
          }
        }
      }

      var results: [String: RenderedMath] = [:]

      for await result in taskGroup {
        if let rendered = result.1 {
          results[result.0] = rendered
        }
      }

      return results
    }
  }
}
