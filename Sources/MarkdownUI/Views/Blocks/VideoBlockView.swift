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
      SizedVideoPlayer(url: url, explicitWidth: width, explicitHeight: height)
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
}

#if canImport(AVKit) && os(macOS)
private struct SizedVideoPlayer: View {
  let url: URL
  let explicitWidth: Int?
  let explicitHeight: Int?

  @State private var naturalAspectRatio: CGFloat?

  var body: some View {
    AVPlayerViewRepresentable(url: url)
      .aspectRatio(effectiveAspectRatio, contentMode: .fit)
      .frame(maxWidth: explicitWidth.map(CGFloat.init))
      .task(id: url) { await loadAspectRatio() }
  }

  private var effectiveAspectRatio: CGFloat {
    if let w = explicitWidth, let h = explicitHeight, h > 0 {
      return CGFloat(w) / CGFloat(h)
    }
    return naturalAspectRatio ?? 16.0 / 9.0
  }

  private func loadAspectRatio() async {
    let asset = AVURLAsset(url: url)
    do {
      let tracks = try await asset.loadTracks(withMediaType: .video)
      guard let track = tracks.first else { return }
      let size = try await track.load(.naturalSize)
      guard size.height > 0 else { return }
      await MainActor.run { naturalAspectRatio = size.width / size.height }
    } catch {
      // Asset didn't report size; aspectRatio falls through to the 16:9 default.
    }
  }
}

private struct AVPlayerViewRepresentable: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> AVPlayerView {
    let view = AVPlayerView()
    view.controlsStyle = .inline
    view.videoGravity = .resizeAspect
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
