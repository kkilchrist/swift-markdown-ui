import SwiftUI

/// A type that provides custom rendering for inline math expressions.
///
/// Use this protocol to render inline math expressions (delimited by `$...$`)
/// as custom views instead of the default monospace text rendering.
///
/// To configure the current inline math provider for a view hierarchy, use the
/// `markdownInlineMathProvider(_:)` modifier.
///
/// The following example shows how to render math with a LaTeX renderer:
///
/// ```swift
/// struct MyMathProvider: InlineMathProvider {
///     func makeBody(content: String) -> AnyView? {
///         AnyView(LaTeXView(content))
///     }
/// }
///
/// Markdown(document)
///     .markdownInlineMathProvider(MyMathProvider())
/// ```
public protocol InlineMathProvider {
    /// Returns a custom view for the given math expression, or `nil` to use default rendering.
    ///
    /// The ``Markdown`` views in a view hierarchy where this provider is the current inline math provider
    /// will call this method for each inline math expression in their contents.
    ///
    /// - Parameter content: The math expression content (without the `$` delimiters).
    /// - Returns: A custom view to render this math, or `nil` to fall back to default rendering.
    func makeBody(content: String) -> AnyView?
}

/// An inline math provider that always returns nil, using default monospace text rendering.
public struct DefaultInlineMathProvider: InlineMathProvider {
    public init() {}

    public func makeBody(content: String) -> AnyView? {
        nil
    }
}

extension InlineMathProvider where Self == DefaultInlineMathProvider {
    /// An inline math provider that uses default rendering (monospace text) for all math expressions.
    public static var `default`: Self {
        DefaultInlineMathProvider()
    }
}
