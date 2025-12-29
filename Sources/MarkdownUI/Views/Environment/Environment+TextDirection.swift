import SwiftUI

/// The text direction mode for Markdown content.
public enum MarkdownTextDirectionMode: Sendable {
  /// Automatically detect text direction per block using the Unicode Bidirectional Algorithm.
  case automatic
  /// Force left-to-right layout for all blocks.
  case leftToRight
  /// Force right-to-left layout for all blocks.
  case rightToLeft
}

extension EnvironmentValues {
  var markdownTextDirectionMode: MarkdownTextDirectionMode {
    get { self[MarkdownTextDirectionModeKey.self] }
    set { self[MarkdownTextDirectionModeKey.self] = newValue }
  }
}

private struct MarkdownTextDirectionModeKey: EnvironmentKey {
  static let defaultValue: MarkdownTextDirectionMode = .automatic
}

extension View {
  /// Sets the text direction mode for Markdown content.
  ///
  /// Use this modifier to control how text direction is determined for Markdown blocks.
  ///
  /// ```swift
  /// // Automatic per-block detection (default)
  /// Markdown(content)
  ///
  /// // Force RTL for entire document
  /// Markdown(content)
  ///   .markdownTextDirection(.rightToLeft)
  ///
  /// // Force LTR for entire document
  /// Markdown(content)
  ///   .markdownTextDirection(.leftToRight)
  /// ```
  ///
  /// - Parameter mode: The text direction mode to use.
  ///   - `.automatic`: Detect direction per block based on content (default).
  ///   - `.leftToRight`: Force LTR layout for all blocks.
  ///   - `.rightToLeft`: Force RTL layout for all blocks.
  /// - Returns: A view with the specified text direction mode.
  public func markdownTextDirection(_ mode: MarkdownTextDirectionMode) -> some View {
    self.environment(\.markdownTextDirectionMode, mode)
  }
}
