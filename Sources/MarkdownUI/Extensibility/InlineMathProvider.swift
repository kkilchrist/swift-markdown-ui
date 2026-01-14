import SwiftUI

/// A type that renders inline math expressions as images for embedding in text.
///
/// Use this protocol to render inline math expressions (delimited by `$...$`)
/// as images that flow inline with surrounding text.
///
/// To configure the current inline math provider for a view hierarchy, use the
/// `markdownInlineMathProvider(_:)` modifier.
///
/// The following example shows how to render math with a KaTeX renderer:
///
/// ```swift
/// struct KaTeXMathProvider: InlineMathProvider {
///     func image(for math: String) async throws -> Image {
///         // Render math to image using KaTeX
///         return try await renderKaTeXToImage(math)
///     }
/// }
///
/// Markdown(document)
///     .markdownInlineMathProvider(KaTeXMathProvider())
/// ```
public protocol InlineMathProvider {
    /// Renders the given math expression as an image for inline display.
    ///
    /// ``Markdown`` views call this method to render inline math expressions
    /// as images that can be embedded within a line of text.
    ///
    /// - Parameter math: The math expression content (without the `$` delimiters).
    /// - Returns: An image containing the rendered math expression.
    /// - Throws: If the math cannot be rendered (falls back to monospace text).
    func image(for math: String) async throws -> Image
}

/// An inline math provider that renders math as monospace text (no custom rendering).
public struct DefaultInlineMathProvider: InlineMathProvider {
    public init() {}

    public func image(for math: String) async throws -> Image {
        // Throw to indicate no custom rendering - fall back to monospace text
        throw InlineMathRenderingError.noCustomProvider
    }
}

/// Errors that can occur during inline math rendering.
public enum InlineMathRenderingError: Error {
    /// No custom provider is configured; use default monospace rendering.
    case noCustomProvider
    /// The math expression could not be rendered.
    case renderingFailed(String)
}

extension InlineMathProvider where Self == DefaultInlineMathProvider {
    /// An inline math provider that uses default rendering (monospace text) for all math expressions.
    public static var `default`: Self {
        DefaultInlineMathProvider()
    }
}
