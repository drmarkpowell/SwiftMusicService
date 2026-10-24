import Foundation

/// The playlists and songs a mock catalog serves.
public struct MockCatalogData: Sendable {
    public var playlists: [MusicPlaylist]
    public var tracksByPlaylist: [MusicItemIdentifier: [MusicTrack]]

    public init(playlists: [MusicPlaylist], tracksByPlaylist: [MusicItemIdentifier: [MusicTrack]]) {
        self.playlists = playlists
        self.tracksByPlaylist = tracksByPlaylist
    }

    var allTracks: [MusicTrack] {
        tracksByPlaylist.values.flatMap { $0 }
    }

    /// Ten mood-style playlists of 8 to 12 generated songs each. The same every run.
    public static let standard: MockCatalogData = {
        let names = [
            "Feeling Good", "Chill Vibes", "Workout Energy", "Focus Time", "Rainy Day",
            "Road Trip", "Dinner Party", "Sunday Morning", "Late Night Drive", "Throwback Party"
        ]
        let adjectives = [
            "Golden", "Quiet", "Electric", "Velvet", "Paper", "Neon",
            "Hollow", "Sunlit", "Midnight", "Crystal", "Restless", "Gentle"
        ]
        let nouns = [
            "Skyline", "Harbor", "Echo", "Garden", "Circuit", "Horizon",
            "Lantern", "River", "Static", "Orchard", "Compass", "Tide"
        ]
        let artists = [
            "The Fictional Few", "Maple & Moss", "Static Bloom", "Juno Park",
            "Low Tide Radio", "Paper Satellites", "Nina Vale", "The Placeholders"
        ]

        var playlists: [MusicPlaylist] = []
        var tracksByPlaylist: [MusicItemIdentifier: [MusicTrack]] = [:]
        var trackNumber = 0

        for (index, name) in names.enumerated() {
            let slug = name.lowercased().replacing(" ", with: "-")
            let playlistID = MusicItemIdentifier("pl.mock.\(slug)")
            let hue = (Double(index) * 0.097).truncatingRemainder(dividingBy: 1)
            playlists.append(
                MusicPlaylist(
                    id: playlistID,
                    name: name,
                    curatorName: "Mock Music",
                    descriptionText: "Placeholder songs for \(name).",
                    artwork: .placeholder(hue: hue),
                    url: URL(string: "https://music.apple.com/us/playlist/\(slug)/\(playlistID.rawValue)"),
                    source: .catalog
                )
            )

            var tracks: [MusicTrack] = []
            for _ in 0..<(8 + index % 5) {
                let adjective = adjectives[trackNumber % adjectives.count]
                let noun = nouns[(trackNumber / adjectives.count + trackNumber) % nouns.count]
                let trackHue = (hue + Double(trackNumber) * 0.031).truncatingRemainder(dividingBy: 1)
                tracks.append(
                    MusicTrack(
                        id: MusicItemIdentifier("i.mock.\(trackNumber)"),
                        title: "\(adjective) \(noun)",
                        artistName: artists[(trackNumber * 5) % artists.count],
                        albumTitle: "\(noun) Sessions",
                        duration: TimeInterval(120 + (trackNumber * 37) % 150),
                        artwork: .placeholder(hue: trackHue),
                        url: URL(string: "https://music.apple.com/us/song/i.mock.\(trackNumber)")
                    )
                )
                trackNumber += 1
            }
            tracksByPlaylist[playlistID] = tracks
        }

        return MockCatalogData(playlists: playlists, tracksByPlaylist: tracksByPlaylist)
    }()
}
