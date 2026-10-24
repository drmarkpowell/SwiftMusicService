import MusicKit
import MusicService
import SwiftUI

/// Draws artwork with MusicKit's `ArtworkImage` when the artwork came from MusicKit, and falls back to
/// ``MusicArtworkView`` for mock artwork and for anything without a native MusicKit object.
///
/// Use this instead of ``MusicArtworkView`` in apps that run on live MusicKit. Some MusicKit artwork,
/// such as the player queue's, uses `musicKit://` URLs that `AsyncImage` cannot load.
public struct LiveArtworkView: View {
    private let artwork: MusicArtwork?
    private let size: CGFloat
    private let isDecorative: Bool

    public init(_ artwork: MusicArtwork?, size: CGFloat, isDecorative: Bool = true) {
        self.artwork = artwork
        self.size = size
        self.isDecorative = isDecorative
    }

    public var body: some View {
        if let native = artwork?.native?.unwrap(as: Artwork.self) {
            ArtworkImage(native, width: size, height: size)
                .frame(width: size, height: size)
                .clipShape(.rect(cornerRadius: size * 0.08))
                .accessibilityHidden(isDecorative)
        } else {
            MusicArtworkView(artwork, size: size, isDecorative: isDecorative)
        }
    }
}
