import Foundation

public extension Sequence where Element == InlineNode {
  public func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.flatMap { try $0.collect(c) }
  }
}

public extension InlineNode {
  public func collect<Result>(_ c: (InlineNode) throws -> [Result]) rethrows -> [Result] {
    try self.children.collect(c) + c(self)
  }
}
