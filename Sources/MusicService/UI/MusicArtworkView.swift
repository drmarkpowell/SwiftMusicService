import SwiftUI

/// Draws artwork from its URL, or a gradient with a note glyph when there is none.
///
/// Artwork is hidden from VoiceOver by default. Pass `isDecorative: false` to add your own
/// accessibility label and traits.
public struct MusicArtworkView: View {
    private let artwork: MusicArtwork?
    private let size: CGFloat
    private let isDecorative: Bool

    public init(_ artwork: MusicArtwork?, size: CGFloat, isDecorative: Bool = true) {
        self.artwork = artwork
        self.size = size
        self.isDecorative = isDecorative
    }

    public var body: some View {
        Group {
            if let url = artwork?.url {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    PlaceholderArtwork(hue: artwork?.hue ?? 0.6)
                }
            } else {
                PlaceholderArtwork(hue: artwork?.hue ?? 0.6)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.08))
        .accessibilityHidden(isDecorative)
    }
}

private struct PlaceholderArtwork: View {
    let hue: Double

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hue: hue, saturation: 0.55, brightness: 0.95),
                    Color(hue: (hue + 0.12).truncatingRemainder(dividingBy: 1), saturation: 0.75, brightness: 0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .resizable()
                .scaledToFit()
                .padding(24)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

#Preview {
    HStack {
        MusicArtworkView(.placeholder(hue: 0.1), size: 96)
        MusicArtworkView(.placeholder(hue: 0.6), size: 96)
    }
}
