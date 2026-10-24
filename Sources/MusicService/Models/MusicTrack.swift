import Foundation

/// A song, independent of any music framework.
public struct MusicTrack: Identifiable, Hashable, Sendable {
    public let id: MusicItemIdentifier
    public var title: String
    public var artistName: String
    public var albumTitle: String?
    /// Length in seconds. Zero when unknown.
    public var duration: TimeInterval
    public var artwork: MusicArtwork?
    public var url: URL?

    public init(
        id: MusicItemIdentifier,
        title: String,
        artistName: String,
        albumTitle: String? = nil,
        duration: TimeInterval = 0,
        artwork: MusicArtwork? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.duration = duration
        self.artwork = artwork
        self.url = url
    }
}
