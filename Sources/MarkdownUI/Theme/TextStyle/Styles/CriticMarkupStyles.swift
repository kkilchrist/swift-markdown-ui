import SwiftUI
import MarkdownUICore

// MARK: - CriticMarkup Text Styles

/// A text style for CriticMarkup additions ({++text++}).
/// Green foreground color with underline.
public struct CriticAdditionStyle: TextStyle {
  public init() {}

  public func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.foregroundColor = .green
    attributes.underlineStyle = .single
  }
}

/// A text style for CriticMarkup deletions ({--text--}).
/// Red foreground color with strikethrough.
public struct CriticDeletionStyle: TextStyle {
  public init() {}

  public func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.foregroundColor = .red
    attributes.strikethroughStyle = .single
  }
}

/// A text style for CriticMarkup comments ({>>comment<<}).
/// Orange background with italic style.
public struct CriticCommentStyle: TextStyle {
  public init() {}

  public func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.backgroundColor = .orange.opacity(0.3)
    // Note: Italic is handled via FontStyle, but we can set it here for AttributedString
    var fontProperties = attributes.fontProperties ?? FontProperties()
    fontProperties.italic = true
    attributes.fontProperties = fontProperties
  }
}
