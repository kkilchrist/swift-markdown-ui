import Foundation

public struct Indexed<Value> {
  public let index: Int
  public let value: Value
}

extension Indexed: Equatable where Value: Equatable {}
extension Indexed: Hashable where Value: Hashable {}

public extension Sequence {
  func indexed() -> [Indexed<Element>] {
    zip(0..., self).map { index, value in
      Indexed(index: index, value: value)
    }
  }
}
