import Foundation
import MarkdownUICore

/// A text style that sets paragraph spacing for soft break rendering.
///
/// Use this within a `.softBreak` theme modifier to control vertical spacing
/// after soft breaks rendered as line breaks.
///
/// ```swift
/// let theme = Theme()
///     .softBreak {
///         Spacing(.em(0.5))
///     }
/// ```
public struct Spacing: TextStyle {
  private let spacing: RelativeSize

  /// Creates a spacing style with a fixed point value.
  /// - Parameter points: The spacing in points.
  public init(_ points: CGFloat) {
    self.spacing = .init(value: points, unit: .rem)
  }

  /// Creates a spacing style with a relative size.
  /// - Parameter relativeSize: The spacing relative to the font size.
  public init(_ relativeSize: RelativeSize) {
    self.spacing = relativeSize
  }

  public func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.softBreakSpacing = self.spacing
  }
}
