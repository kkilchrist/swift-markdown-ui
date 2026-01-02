import Foundation
import MarkdownUICore

/// A style that configures the appearance of soft breaks in Markdown content.
///
/// Soft breaks are intentional line breaks created by trailing double-space or `<br>` in markdown.
/// This style allows adding vertical spacing after these breaks, distinct from naturally wrapped lines.
///
/// Use the ``Theme/softBreak(_:)`` method to apply a soft break style to a theme:
///
/// ```swift
/// let theme = Theme()
///     .softBreak {
///         Spacing(.em(0.5))
///     }
/// ```
public struct SoftBreakStyle: Sendable {
  /// The vertical spacing to add after a soft break when rendered as a line break.
  public var spacing: RelativeSize?

  /// Creates a soft break style with the given spacing.
  /// - Parameter spacing: The spacing to add after soft breaks. Defaults to `nil` (no extra spacing).
  public init(spacing: RelativeSize? = nil) {
    self.spacing = spacing
  }

  /// The default soft break style with no additional spacing.
  public static let `default` = SoftBreakStyle()
}
