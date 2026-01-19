import SwiftUI

extension View {
    /// Sets the inline math provider for the Markdown inline math expressions in a view hierarchy.
    ///
    /// Use this modifier to provide custom rendering for inline math (delimited by `$...$`).
    ///
    /// - Parameter inlineMathProvider: The inline math provider to set. Use ``InlineMathProvider/default``
    ///                                 for standard monospace text rendering, or a custom provider that you define
    ///                                 by creating a type that conforms to the ``InlineMathProvider`` protocol.
    /// - Returns: A view that uses the specified inline math provider for itself and its child views.
    public func markdownInlineMathProvider(_ inlineMathProvider: some InlineMathProvider) -> some View {
        self.environment(\.inlineMathProvider, AnyInlineMathProvider(inlineMathProvider))
    }
}

extension EnvironmentValues {
    var inlineMathProvider: AnyInlineMathProvider {
        get { self[InlineMathProviderKey.self] }
        set { self[InlineMathProviderKey.self] = newValue }
    }
}

private struct InlineMathProviderKey: EnvironmentKey {
    static let defaultValue: AnyInlineMathProvider = .init(.default)
}

/// Type-erased wrapper for InlineMathProvider
struct AnyInlineMathProvider: InlineMathProvider {
    private let _image: (String) async throws -> Image
    private let _renderedMath: (String) async throws -> RenderedMath
    private let _cachedRenderedMath: (String) -> RenderedMath?

    init(_ provider: some InlineMathProvider) {
        self._image = { math in
            try await provider.image(for: math)
        }
        self._renderedMath = { math in
            try await provider.renderedMath(for: math)
        }
        self._cachedRenderedMath = { math in
            provider.cachedRenderedMath(for: math)
        }
    }

    func image(for math: String) async throws -> Image {
        try await _image(math)
    }

    func renderedMath(for math: String) async throws -> RenderedMath {
        try await _renderedMath(math)
    }

    func cachedRenderedMath(for math: String) -> RenderedMath? {
        _cachedRenderedMath(math)
    }
}
