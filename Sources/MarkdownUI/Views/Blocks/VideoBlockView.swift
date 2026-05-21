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
    // Pass through full URLs with a scheme (http/https/file/data) unchanged.
    if let url = URL(string: source), url.scheme != nil {
      return url
    }
    guard let baseURL = imageBaseURL else { return nil }

    // Markdown sources are conceptually URL-encoded but AVFoundation file lookup
    // expects literal filesystem paths — feeding it "file:///…/Screen%20Recording.mov"
    // sometimes fails where "/…/Screen Recording.mov" succeeds. Decode the source
    // and use URL(fileURLWithPath:), which is the canonical file-URL constructor.
    let decodedPath = source.removingPercentEncoding ?? source
    if decodedPath.hasPrefix("/") {
      return URL(fileURLWithPath: decodedPath)
    }
    let documentDir = baseURL.deletingLastPathComponent()
    return URL(fileURLWithPath: decodedPath, relativeTo: documentDir).absoluteURL
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
    // No-op. url is immutable per view instance — when the URL changes
    // SwiftUI tears this view down and calls makeNSView() again. Previously
    // we compared currentItem.asset.url here, but AVPlayer normalizes the
    // stored URL, so the comparison sometimes flagged identical URLs as
    // different and reset the player mid-load each time @State updated.
  }
}
#endif
