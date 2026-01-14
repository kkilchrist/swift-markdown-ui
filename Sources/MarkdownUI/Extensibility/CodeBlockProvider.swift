import SwiftUI

/// A type that provides custom rendering for code blocks based on their language.
///
/// Use this protocol to render code blocks with specific languages (like `mermaid`, `math`, `smiles`)
/// as custom views instead of the default syntax-highlighted code.
///
/// To configure the current code block provider for a view hierarchy, use the
/// `markdownCodeBlockProvider(_:)` modifier.
///
/// The following example shows how to render Mermaid diagrams:
///
/// ```swift
/// struct MyCodeBlockProvider: CodeBlockProvider {
///     func makeBody(language: String?, content: String) -> AnyView? {
///         guard language == "mermaid" else { return nil }
///         return AnyView(MermaidView(content: content))
///     }
/// }
///
/// Markdown(document)
///     .markdownCodeBlockProvider(MyCodeBlockProvider())
/// ```
public protocol CodeBlockProvider {
    /// Returns a custom view for the given code block, or `nil` to use default rendering.
    ///
    /// The ``Markdown`` views in a view hierarchy where this provider is the current code block provider
    /// will call this method for each code block in their contents.
    ///
    /// - Parameters:
    ///   - language: The language identifier from the code fence (e.g., "swift", "mermaid").
    ///   - content: The content of the code block.
    /// - Returns: A custom view to render this block, or `nil` to fall back to default rendering.
    func makeBody(language: String?, content: String) -> AnyView?
}

/// A code block provider that always returns nil, using default code block rendering.
public struct DefaultCodeBlockProvider: CodeBlockProvider {
    public init() {}

    public func makeBody(language: String?, content: String) -> AnyView? {
        nil
    }
}

extension CodeBlockProvider where Self == DefaultCodeBlockProvider {
    /// A code block provider that uses default rendering for all code blocks.
    public static var `default`: Self {
        DefaultCodeBlockProvider()
    }
}
