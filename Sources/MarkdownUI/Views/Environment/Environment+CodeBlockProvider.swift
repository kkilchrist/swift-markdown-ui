import SwiftUI

extension View {
    /// Sets the code block provider for the Markdown code blocks in a view hierarchy.
    ///
    /// Use this modifier to provide custom rendering for specific code block languages
    /// (like `mermaid`, `math`, or `smiles`).
    ///
    /// - Parameter codeBlockProvider: The code block provider to set. Use ``CodeBlockProvider/default``
    ///                                for standard code block rendering, or a custom provider that you define
    ///                                by creating a type that conforms to the ``CodeBlockProvider`` protocol.
    /// - Returns: A view that uses the specified code block provider for itself and its child views.
    public func markdownCodeBlockProvider(_ codeBlockProvider: some CodeBlockProvider) -> some View {
        self.environment(\.codeBlockProvider, AnyCodeBlockProvider(codeBlockProvider))
    }
}

extension EnvironmentValues {
    var codeBlockProvider: AnyCodeBlockProvider {
        get { self[CodeBlockProviderKey.self] }
        set { self[CodeBlockProviderKey.self] = newValue }
    }
}

private struct CodeBlockProviderKey: EnvironmentKey {
    static let defaultValue: AnyCodeBlockProvider = .init(.default)
}

/// Type-erased wrapper for CodeBlockProvider
struct AnyCodeBlockProvider: CodeBlockProvider {
    private let _makeBody: (String?, String) -> AnyView?

    init(_ provider: some CodeBlockProvider) {
        self._makeBody = { language, content in
            provider.makeBody(language: language, content: content)
        }
    }

    func makeBody(language: String?, content: String) -> AnyView? {
        _makeBody(language, content)
    }
}
