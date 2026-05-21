import SwiftUI

struct VideoBlockView: View {
  let source: String
  let width: Int?
  let height: Int?

  var body: some View {
    let name = URL(string: source)?.lastPathComponent ?? source
    Text("[Video: \(name)]")
      .italic()
      .foregroundStyle(.secondary)
  }
}
