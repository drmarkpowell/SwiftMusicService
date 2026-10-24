import Foundation

/// Album or playlist artwork. Live artwork carries a URL; mock artwork has none and is
/// drawn as a gradient from `hue` by ``MusicArtworkView``.
public struct MusicArtwork: Hashable, Sendable {
    public var url: URL?
    /// Hue (0...1) used for the placeholder gradient when there is no URL.
    public var hue: Double

    public init(url: URL? = nil, hue: Double = 0.6) {
        self.url = url
        self.hue = hue
    }

    public static func placeholder(hue: Double) -> MusicArtwork {
        MusicArtwork(url: nil, hue: hue)
    }
}
