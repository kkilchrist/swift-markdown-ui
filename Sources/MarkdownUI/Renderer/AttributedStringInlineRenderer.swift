import Foundation
import MarkdownUICore

#if canImport(UIKit)
import UIKit
import MarkdownUICore
#elseif canImport(AppKit)
import AppKit
#endif

extension InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer,
    fontProperties: FontProperties? = nil
  ) -> AttributedString {
    var renderer = AttributedStringInlineRenderer(
      baseURL: baseURL,
      textStyles: textStyles,
      softBreakMode: softBreakMode,
      attributes: attributes,
      fontProperties: fontProperties
    )
    renderer.render(self)
    return renderer.result.resolvingFonts()
  }
}

private struct AttributedStringInlineRenderer {
  var result = AttributedString()

  private let baseURL: URL?
  private let textStyles: InlineTextStyles
  private let softBreakMode: SoftBreak.Mode
  private let fontProperties: FontProperties?
  private var attributes: AttributeContainer
  private var shouldSkipNextWhitespace = false
  private var pendingSoftBreakSpacing: CGFloat?

  init(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer,
    fontProperties: FontProperties? = nil
  ) {
    self.baseURL = baseURL
    self.textStyles = textStyles
    self.softBreakMode = softBreakMode
    self.attributes = attributes
    self.fontProperties = fontProperties
  }

  mutating func render(_ inline: InlineNode) {
    switch inline {
    case .text(let content):
      self.renderText(content)
    case .softBreak:
      self.renderSoftBreak()
    case .lineBreak:
      self.renderLineBreak()
    case .code(let content):
      self.renderCode(content)
    case .html(let content):
      self.renderHTML(content)
    case .emphasis(let children):
      self.renderEmphasis(children: children)
    case .strong(let children):
      self.renderStrong(children: children)
    case .strikethrough(let children):
      self.renderStrikethrough(children: children)
    case .highlight(let children):
      self.renderHighlight(children: children)
    case .link(let destination, let children):
      self.renderLink(destination: destination, children: children)
    case .image(let source, let children):
      self.renderImage(source: source, children: children)
    case .criticAddition(let children):
      self.renderCriticAddition(children: children)
    case .criticDeletion(let children):
      self.renderCriticDeletion(children: children)
    case .criticSubstitution(let oldContent, let newContent):
      self.renderCriticSubstitution(oldContent: oldContent, newContent: newContent)
    case .criticComment(let children):
      self.renderCriticComment(children: children)
    case .criticHighlight(let children):
      self.renderCriticHighlight(children: children)
    case .math(let content):
      self.renderMath(content)
    }
  }

  private mutating func renderText(_ text: String) {
    var text = text

    if self.shouldSkipNextWhitespace {
      self.shouldSkipNextWhitespace = false
      text = text.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }

    if let spacing = self.pendingSoftBreakSpacing, spacing > 0 {
      var textAttributes = self.attributes
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.paragraphSpacingBefore = spacing
      textAttributes.paragraphStyle = paragraphStyle
      self.result += .init(text, attributes: textAttributes)
      self.pendingSoftBreakSpacing = nil
    } else {
      self.result += .init(text, attributes: self.attributes)
    }
  }

  private mutating func renderSoftBreak() {
    switch softBreakMode {
    case .space where self.shouldSkipNextWhitespace:
      self.shouldSkipNextWhitespace = false
    case .space:
      self.result += .init(" ", attributes: self.attributes)
    case .lineBreak:
      self.renderLineBreak()
    }
  }

  private mutating func renderLineBreak() {
    self.result += .init("\n", attributes: self.attributes)
    if let spacing = textStyles.softBreak.spacing {
      self.pendingSoftBreakSpacing = spacing.points(relativeTo: fontProperties)
    }
  }

  private mutating func renderCode(_ code: String) {
    self.result += .init(code, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }

  private mutating func renderHTML(_ html: String) {
    let tag = HTMLTag(html)

    switch tag?.name.lowercased() {
    case "br":
      self.renderLineBreak()
      self.shouldSkipNextWhitespace = true
    default:
      self.renderText(html)
    }
  }

  private mutating func renderEmphasis(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.emphasis.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrong(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strong.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderStrikethrough(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.strikethrough.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderHighlight(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.highlight.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderLink(destination: String, children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.link.mergingAttributes(self.attributes)
    self.attributes.link = URL(string: destination, relativeTo: self.baseURL)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderImage(source: String, children: [InlineNode]) {
    // AttributedString does not support images
  }

  // MARK: - CriticMarkup Rendering

  private mutating func renderCriticAddition(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.criticAddition.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderCriticDeletion(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.criticDeletion.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderCriticSubstitution(oldContent: [InlineNode], newContent: [InlineNode]) {
    print("DEBUG renderCriticSubstitution: oldContent=\(oldContent), newContent=\(newContent)")

    // Render old content with deletion style
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.criticSubstitutionOld.mergingAttributes(self.attributes)
    print("DEBUG: After criticSubstitutionOld merge, fg=\(String(describing: self.attributes.foregroundColor))")

    for child in oldContent {
      self.render(child)
    }

    // Render new content with addition style
    self.attributes = self.textStyles.criticSubstitutionNew.mergingAttributes(savedAttributes)
    print("DEBUG: After criticSubstitutionNew merge, fg=\(String(describing: self.attributes.foregroundColor))")

    for child in newContent {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderCriticComment(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.criticComment.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderCriticHighlight(children: [InlineNode]) {
    let savedAttributes = self.attributes
    self.attributes = self.textStyles.criticHighlight.mergingAttributes(self.attributes)

    for child in children {
      self.render(child)
    }

    self.attributes = savedAttributes
  }

  private mutating func renderMath(_ math: String) {
    // Render math as monospace code-like text in AttributedString
    self.result += .init(math, attributes: self.textStyles.code.mergingAttributes(self.attributes))
  }
}

extension TextStyle {
  fileprivate func mergingAttributes(_ attributes: AttributeContainer) -> AttributeContainer {
    var newAttributes = attributes
    self._collectAttributes(in: &newAttributes)
    return newAttributes
  }
}
