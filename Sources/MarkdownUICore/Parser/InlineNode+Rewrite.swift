import Foundation

public extension Sequence where Element == InlineNode {
  public func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [InlineNode] {
    try self.flatMap { try $0.rewrite(r) }
  }
}

public extension InlineNode {
  public func rewrite(_ r: (InlineNode) throws -> [InlineNode]) rethrows -> [InlineNode] {
    var inline = self
    // .criticSubstitution has two child arrays (oldContent, newContent) that the
    // `children` setter cannot round-trip — writing back via setter collapses both
    // into oldContent. Recurse into each half explicitly so structure is preserved.
    if case .criticSubstitution(let oldContent, let newContent) = inline {
      inline = .criticSubstitution(
        oldContent: try oldContent.rewrite(r),
        newContent: try newContent.rewrite(r)
      )
    } else {
      inline.children = try self.children.rewrite(r)
    }
    return try r(inline)
  }
}
