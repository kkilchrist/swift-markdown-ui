import Foundation

/// A highlighted text inline element (rendered with background color).
///
/// Use this to apply highlight styling to text, similar to the ==text== syntax
/// in Obsidian markdown.
///
/// ```swift
/// Markdown {
///   Paragraph {
///     "This is "
///     Highlight("important")
///     " information."
///   }
/// }
/// ```
public struct Highlight: InlineContentProtocol {
  public var _inlineContent: InlineContent {
    .init(inlines: [.highlight(children: self.content.inlines)])
  }

  private let content: InlineContent

  init(content: InlineContent) {
    self.content = content
  }

  /// Creates a highlighted inline by applying the highlight style to a string.
  /// - Parameter text: The text to highlight.
  public init(_ text: String) {
    self.init(content: .init(inlines: [.text(text)]))
  }

  /// Creates a highlighted inline by applying the highlight style to other inline content.
  /// - Parameter content: An inline content builder that returns the inlines to highlight.
  public init(@InlineContentBuilder content: () -> InlineContent) {
    self.init(content: content())
  }
}
