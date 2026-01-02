import Foundation
import CoreGraphics

public struct RawImageData: Hashable {
  public var source: String
  public var alt: String
  public var destination: String?
  public var maxWidth: CGFloat?
  public var maxHeight: CGFloat?
}

/// Parses Obsidian-style image dimensions from alt text.
/// Supports: `alt|500` (width only) or `alt|500x300` (width and height)
private func parseImageDimensions(from altText: String) -> (cleanAlt: String, maxWidth: CGFloat?, maxHeight: CGFloat?) {
  // Pattern: everything before |, then digits, optionally x and more digits
  let pattern = #"^(.*?)\|(\d+)(?:x(\d+))?$"#

  guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
    return (altText, nil, nil)
  }

  let nsRange = NSRange(altText.startIndex..., in: altText)
  guard let match = regex.firstMatch(in: altText, options: [], range: nsRange) else {
    return (altText, nil, nil)
  }

  // Extract clean alt text (group 1)
  let cleanAlt: String
  if let range = Range(match.range(at: 1), in: altText) {
    cleanAlt = String(altText[range])
  } else {
    cleanAlt = ""
  }

  // Extract width (group 2)
  var width: CGFloat? = nil
  if let range = Range(match.range(at: 2), in: altText),
     let value = Double(altText[range]) {
    width = CGFloat(value)
  }

  // Extract height (group 3) - optional
  var height: CGFloat? = nil
  if match.range(at: 3).location != NSNotFound,
     let range = Range(match.range(at: 3), in: altText),
     let value = Double(altText[range]) {
    height = CGFloat(value)
  }

  return (cleanAlt, width, height)
}

public extension InlineNode {
  var imageData: RawImageData? {
    switch self {
    case .image(let source, let children):
      let fullAlt = children.renderPlainText()
      let (cleanAlt, maxWidth, maxHeight) = parseImageDimensions(from: fullAlt)
      return .init(source: source, alt: cleanAlt, maxWidth: maxWidth, maxHeight: maxHeight)
    case .link(let destination, let children) where children.count == 1:
      guard var imageData = children.first?.imageData else { return nil }
      imageData.destination = destination
      return imageData
    default:
      return nil
    }
  }
}
