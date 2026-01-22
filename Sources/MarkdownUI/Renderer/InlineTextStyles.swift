import Foundation
import MarkdownUICore

struct InlineTextStyles {
  let code: TextStyle
  let emphasis: TextStyle
  let strong: TextStyle
  let strikethrough: TextStyle
  let highlight: TextStyle
  let link: TextStyle
  let softBreak: SoftBreakStyle

  // CriticMarkup styles
  let criticAddition: TextStyle
  let criticDeletion: TextStyle
  let criticSubstitutionOld: TextStyle
  let criticSubstitutionNew: TextStyle
  let criticComment: TextStyle
  let criticHighlight: TextStyle
}
