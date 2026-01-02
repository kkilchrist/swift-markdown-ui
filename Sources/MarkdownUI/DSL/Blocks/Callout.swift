import Foundation
import MarkdownUICore

/// An Obsidian-style callout block element.
///
/// Callouts are styled block elements that highlight important information
/// with an icon, color, and optional title.
///
/// ```swift
/// Markdown {
///   Callout(.warning, title: "Be Careful") {
///     Paragraph {
///       "This action cannot be undone."
///     }
///   }
/// }
/// ```
///
/// You can also use a custom callout type string:
///
/// ```swift
/// Markdown {
///   Callout("custom") {
///     Paragraph {
///       "Custom callout content"
///     }
///   }
/// }
/// ```
public struct Callout: MarkdownContentProtocol {
  public var _markdownContent: MarkdownContent {
    .init(blocks: [.callout(type: type, title: title, children: content.blocks)])
  }

  private let type: String
  private let title: String?
  private let content: MarkdownContent

  /// Creates a callout with a predefined callout type.
  /// - Parameters:
  ///   - type: The callout type (e.g., `.note`, `.warning`, `.tip`).
  ///   - title: An optional custom title. If nil, the callout type name is used.
  ///   - content: A Markdown content builder that returns the content of the callout.
  public init(
    _ type: CalloutType,
    title: String? = nil,
    @MarkdownContentBuilder content: () -> MarkdownContent
  ) {
    self.type = type.rawValue
    self.title = title
    self.content = content()
  }

  /// Creates a callout with a custom type string.
  /// - Parameters:
  ///   - type: The callout type as a string (e.g., "note", "warning").
  ///   - title: An optional custom title.
  ///   - content: A Markdown content builder that returns the content of the callout.
  public init(
    _ type: String,
    title: String? = nil,
    @MarkdownContentBuilder content: () -> MarkdownContent
  ) {
    self.type = type
    self.title = title
    self.content = content()
  }
}
