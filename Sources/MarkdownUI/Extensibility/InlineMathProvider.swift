import SwiftUI

/// Rendered math result containing the image and baseline alignment information.
public struct RenderedMath: Sendable {
    /// The rendered math as an image.
    public let image: Image
    /// The baseline offset to apply for proper vertical alignment.
    /// Negative values shift the image down, positive values shift it up.
    public let baselineOffset: CGFloat

    public init(image: Image, baselineOffset: CGFloat = 0) {
        self.image = image
        self.baselineOffset = baselineOffset
    }
}

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
///     func renderedMath(for math: String) async throws -> RenderedMath {
///         // Render math to image using KaTeX
///         let (image, baselineOffset) = try await renderKaTeXToImage(math)
///         return RenderedMath(image: image, baselineOffset: baselineOffset)
///     }
/// }
///
/// Markdown(document)
///     .markdownInlineMathProvider(KaTeXMathProvider())
/// ```
public protocol InlineMathProvider {
    /// Renders the given math expression as an image with baseline information.
    ///
    /// ``Markdown`` views call this method to render inline math expressions
    /// as images that can be embedded within a line of text.
    ///
    /// - Parameter math: The math expression content (without the `$` delimiters).
    /// - Returns: A `RenderedMath` containing the image and baseline offset.
    /// - Throws: If the math cannot be rendered (falls back to monospace text).
    func renderedMath(for math: String) async throws -> RenderedMath

    /// Renders the given math expression as an image for inline display.
    /// - Note: Deprecated. Implement `renderedMath(for:)` instead for proper baseline alignment.
    func image(for math: String) async throws -> Image
}

extension InlineMathProvider {
    /// Default implementation that calls the legacy `image(for:)` method.
    public func renderedMath(for math: String) async throws -> RenderedMath {
        let image = try await image(for: math)
        return RenderedMath(image: image, baselineOffset: 0)
    }

    /// Default implementation that calls `renderedMath(for:)`.
    public func image(for math: String) async throws -> Image {
        try await renderedMath(for: math).image
    }
}

/// An inline math provider that renders math as monospace text (no custom rendering).
public struct DefaultInlineMathProvider: InlineMathProvider {
    public init() {}

    public func renderedMath(for math: String) async throws -> RenderedMath {
        // Throw to indicate no custom rendering - fall back to monospace text
        throw InlineMathRenderingError.noCustomProvider
    }

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
