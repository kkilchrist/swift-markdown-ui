import SwiftUI

#if canImport(AVKit) && os(macOS)
import AVKit
#endif

struct VideoBlockView: View {
  @Environment(\.imageBaseURL) private var imageBaseURL

  let source: String
  let width: Int?
  let height: Int?

  var body: some View {
    #if canImport(AVKit) && os(macOS)
    if let url = resolvedURL {
      AVPlayerViewRepresentable(url: url)
        .frame(width: frameWidth, height: frameHeight)
    } else {
      placeholder
    }
    #else
    placeholder
    #endif
  }

  private var placeholder: some View {
    let name = URL(string: source)?.lastPathComponent ?? source
    return Text("[Video: \(name)]")
      .italic()
      .foregroundStyle(.secondary)
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
    // Fall back to 16:9 when only a width was specified so the player has a size to render into.
    return width.map { CGFloat($0) * 9.0 / 16.0 }
  }
}

#if canImport(AVKit) && os(macOS)
private struct AVPlayerViewRepresentable: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> AVPlayerView {
    let view = AVPlayerView()
    view.controlsStyle = .inline
    view.player = AVPlayer(url: url)
    return view
  }

  func updateNSView(_ nsView: AVPlayerView, context: Context) {
    let currentURL = (nsView.player?.currentItem?.asset as? AVURLAsset)?.url
    if currentURL != url {
      nsView.player = AVPlayer(url: url)
    }
  }
}
#endif
