import SwiftUI
import MarkdownUICore

extension CalloutType {
  /// The default SwiftUI Color for this callout type.
  ///
  /// This extension adds SwiftUI-specific color support to CalloutType.
  /// For HTML rendering, use `cssColor` instead.
  public var color: Color {
    switch self {
    case .note:
      return .blue
    case .abstract, .summary:
      return .cyan
    case .info:
      return .blue
    case .todo:
      return .blue
    case .tip, .hint, .important:
      return .cyan
    case .success, .check, .done:
      return .green
    case .question, .help, .faq:
      return .orange
    case .warning, .caution, .attention:
      return .orange
    case .failure, .fail, .missing:
      return .red
    case .danger, .error:
      return .red
    case .bug:
      return .red
    case .example:
      return .purple
    case .quote, .cite:
      return .gray
    }
  }
}
