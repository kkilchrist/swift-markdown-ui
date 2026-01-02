import SwiftUI
import MarkdownUICore

/// The properties of a Markdown callout block.
public struct CalloutConfiguration {
  /// A type-erased view of the callout content.
  public struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    public let body: AnyView
  }

  /// The callout type string (e.g., "note", "warning").
  public let type: String

  /// The parsed callout type, if it matches a known type.
  public var calloutType: CalloutType? {
    CalloutType(rawValue: type)
  }

  /// The optional title for the callout.
  public let title: String?

  /// The callout content view.
  public let label: Label

  /// The content of the callout block.
  public let content: MarkdownContent
}
