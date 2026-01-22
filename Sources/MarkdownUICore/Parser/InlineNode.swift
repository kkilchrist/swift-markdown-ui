import Foundation

public enum InlineNode: Hashable, Sendable {
  case text(String)
  case softBreak
  case lineBreak
  case code(String)
  case html(String)
  case emphasis(children: [InlineNode])
  case strong(children: [InlineNode])
  case strikethrough(children: [InlineNode])
  case highlight(children: [InlineNode])
  case link(destination: String, children: [InlineNode])
  case image(source: String, children: [InlineNode])

  // CriticMarkup support
  case criticAddition(children: [InlineNode])      // {++text++}
  case criticDeletion(children: [InlineNode])      // {--text--}
  case criticSubstitution(oldContent: [InlineNode], newContent: [InlineNode])  // {~~old~>new~~}
  case criticComment(children: [InlineNode])       // {>>comment<<}
  case criticHighlight(children: [InlineNode])     // {==highlight==}
}

public extension InlineNode {
  public var children: [InlineNode] {
    get {
      switch self {
      case .emphasis(let children):
        return children
      case .strong(let children):
        return children
      case .strikethrough(let children):
        return children
      case .highlight(let children):
        return children
      case .link(_, let children):
        return children
      case .image(_, let children):
        return children
      case .criticAddition(let children):
        return children
      case .criticDeletion(let children):
        return children
      case .criticSubstitution(let oldContent, let newContent):
        return oldContent + newContent
      case .criticComment(let children):
        return children
      case .criticHighlight(let children):
        return children
      default:
        return []
      }
    }

    set {
      switch self {
      case .emphasis:
        self = .emphasis(children: newValue)
      case .strong:
        self = .strong(children: newValue)
      case .strikethrough:
        self = .strikethrough(children: newValue)
      case .highlight:
        self = .highlight(children: newValue)
      case .link(let destination, _):
        self = .link(destination: destination, children: newValue)
      case .image(let source, _):
        self = .image(source: source, children: newValue)
      case .criticAddition:
        self = .criticAddition(children: newValue)
      case .criticDeletion:
        self = .criticDeletion(children: newValue)
      case .criticSubstitution:
        // For substitution, setting children replaces both old and new with the new value
        self = .criticSubstitution(oldContent: newValue, newContent: [])
      case .criticComment:
        self = .criticComment(children: newValue)
      case .criticHighlight:
        self = .criticHighlight(children: newValue)
      default:
        break
      }
    }
  }
}
