import Foundation

/// A playlist from the Apple Music catalog or from the user's library.
public struct MusicPlaylist: Identifiable, Hashable, Sendable {
    public enum Source: Hashable, Sendable {
        case catalog
        case library
    }

    public let id: MusicItemIdentifier
    public var name: String
    public var curatorName: String?
    public var descriptionText: String?
    public var artwork: MusicArtwork?
    public var url: URL?
    public var source: Source
    /// When the playlist was added to the library. Only set for library playlists.
    public var addedDate: Date?

    public init(
        id: MusicItemIdentifier,
        name: String,
        curatorName: String? = nil,
        descriptionText: String? = nil,
        artwork: MusicArtwork? = nil,
        url: URL? = nil,
        source: Source = .catalog,
        addedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.curatorName = curatorName
        self.descriptionText = descriptionText
        self.artwork = artwork
        self.url = url
        self.source = source
        self.addedDate = addedDate
    }
}
