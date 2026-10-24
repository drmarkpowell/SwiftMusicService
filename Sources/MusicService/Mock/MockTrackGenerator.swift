import Foundation

/// Makes placeholder songs. The same seed always gives the same songs.
enum MockTrackGenerator {
    static let adjectives = [
        "Golden", "Quiet", "Electric", "Velvet", "Paper", "Neon",
        "Hollow", "Sunlit", "Midnight", "Crystal", "Restless", "Gentle"
    ]

    static let nouns = [
        "Skyline", "Harbor", "Echo", "Garden", "Circuit", "Horizon",
        "Lantern", "River", "Static", "Orchard", "Compass", "Tide"
    ]

    static let artists = [
        "The Fictional Few", "Maple & Moss", "Static Bloom", "Juno Park",
        "Low Tide Radio", "Paper Satellites", "Nina Vale", "The Placeholders"
    ]

    /// A stable 64-bit seed for a string. `String.hashValue` changes between launches, so it can't be used.
    static func seed(for string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }

    /// `count` songs with distinct title and artist pairs, which Favorites-style code often keys on.
    static func tracks(seed: UInt64, count: Int, hue: Double) -> [MusicTrack] {
        var generator = SeededGenerator(seed: seed)
        var usedKeys: Set<String> = []
        var tracks: [MusicTrack] = []

        while tracks.count < count {
            let adjective = adjectives[Int(generator.next() % UInt64(adjectives.count))]
            let noun = nouns[Int(generator.next() % UInt64(nouns.count))]
            let artist = artists[Int(generator.next() % UInt64(artists.count))]
            guard usedKeys.insert("\(adjective) \(noun)||\(artist)").inserted else { continue }

            let number = tracks.count
            tracks.append(
                MusicTrack(
                    id: MusicItemIdentifier("i.mock.\(seed).\(number)"),
                    title: "\(adjective) \(noun)",
                    artistName: artist,
                    albumTitle: "\(noun) Sessions",
                    duration: TimeInterval(120 + generator.next() % 150),
                    artwork: .placeholder(hue: (hue + Double(number) * 0.031).truncatingRemainder(dividingBy: 1)),
                    url: URL(string: "https://music.apple.com/us/song/i.mock.\(seed).\(number)")
                )
            )
        }
        return tracks
    }
}
