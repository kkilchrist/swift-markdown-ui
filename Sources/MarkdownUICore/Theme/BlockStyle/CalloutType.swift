import Foundation

/// Defines the available callout types with their associated styling.
///
/// This enum provides the core callout type definitions used by both
/// SwiftUI rendering and HTML export. The `color` property for SwiftUI
/// is provided via an extension in `CalloutType+Color.swift`.
public enum CalloutType: String, CaseIterable, Sendable {
  case note
  case abstract
  case summary
  case info
  case todo
  case tip
  case hint
  case important
  case success
  case check
  case done
  case question
  case help
  case faq
  case warning
  case caution
  case attention
  case failure
  case fail
  case missing
  case danger
  case error
  case bug
  case example
  case quote
  case cite

  /// The SF Symbol name for this callout type.
  public var iconName: String {
    switch self {
    case .note:
      return "pencil"
    case .abstract, .summary:
      return "doc.text"
    case .info:
      return "info.circle"
    case .todo:
      return "checkmark.circle"
    case .tip, .hint, .important:
      return "lightbulb"
    case .success, .check, .done:
      return "checkmark.circle.fill"
    case .question, .help, .faq:
      return "questionmark.circle"
    case .warning, .caution, .attention:
      return "exclamationmark.triangle"
    case .failure, .fail, .missing:
      return "xmark.circle"
    case .danger, .error:
      return "xmark.octagon"
    case .bug:
      return "ladybug"
    case .example:
      return "list.bullet"
    case .quote, .cite:
      return "quote.opening"
    }
  }

  /// A Unicode character suitable for HTML rendering.
  public var htmlIcon: String {
    switch self {
    case .note:
      return "✏️"
    case .abstract, .summary:
      return "📋"
    case .info:
      return "ℹ️"
    case .todo:
      return "☑️"
    case .tip, .hint, .important:
      return "💡"
    case .success, .check, .done:
      return "✅"
    case .question, .help, .faq:
      return "❓"
    case .warning, .caution, .attention:
      return "⚠️"
    case .failure, .fail, .missing:
      return "❌"
    case .danger, .error:
      return "🛑"
    case .bug:
      return "🐛"
    case .example:
      return "📝"
    case .quote, .cite:
      return "💬"
    }
  }

  /// CSS hex color for HTML rendering (no SwiftUI dependency).
  public var cssColor: String {
    switch self {
    case .note, .info, .todo:
      return "#3b82f6"  // blue
    case .abstract, .summary, .tip, .hint, .important:
      return "#06b6d4"  // cyan
    case .success, .check, .done:
      return "#22c55e"  // green
    case .question, .help, .faq, .warning, .caution, .attention:
      return "#f97316"  // orange
    case .failure, .fail, .missing, .danger, .error, .bug:
      return "#ef4444"  // red
    case .example:
      return "#a855f7"  // purple
    case .quote, .cite:
      return "#6b7280"  // gray
    }
  }

  /// Creates a CalloutType from a string, case-insensitive.
  public init?(rawValue: String) {
    let lowercased = rawValue.lowercased()
    if let type = Self.allCases.first(where: { $0.rawValue == lowercased }) {
      self = type
    } else {
      return nil
    }
  }
}
