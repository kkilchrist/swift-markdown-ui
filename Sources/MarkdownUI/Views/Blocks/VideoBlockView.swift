import AVKit
import SwiftUI

struct VideoBlockView: View {
  @Environment(\.imageBaseURL) private var imageBaseURL

  let source: String
  let width: Int?
  let height: Int?

  var body: some View {
    if let url = resolvedURL {
      VideoPlayer(player: AVPlayer(url: url))
        .frame(width: frameWidth, height: frameHeight)
    } else {
      Text("[Video: \(source)]")
        .italic()
        .foregroundStyle(.secondary)
    }
  }

  private var resolvedURL: URL? {
    if let url = URL(string: source), url.scheme != nil {
      return url
    }
    guard let baseURL = imageBaseURL else { return nil }
    let encoded = source.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? source
    return URL(string: encoded, relativeTo: baseURL)?.absoluteURL
  }

  private var frameWidth: CGFloat? {
    width.map(CGFloat.init)
  }

  private var frameHeight: CGFloat? {
    if let height {
      return CGFloat(height)
    }
    // Fall back to 16:9 when only a width was specified so VideoPlayer has a size to render into.
    return width.map { CGFloat($0) * 9.0 / 16.0 }
  }
}
