import Foundation

public extension InlineNode {
    /// Returns the math content if this is a math inline node, otherwise nil.
    var mathContent: String? {
        switch self {
        case .math(let content):
            return content
        default:
            return nil
        }
    }
}
