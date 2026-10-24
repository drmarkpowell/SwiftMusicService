import Testing
@testable import MusicService

struct MockCatalogDataTests {
    private let data = MockCatalogData.standard

    @Test func hasTenPlaylistsEachWithEightToTwelveSongs() {
        #expect(data.playlists.count == 10)
        for playlist in data.playlists {
            let count = data.tracksByPlaylist[playlist.id]?.count ?? 0
            #expect((8...12).contains(count), "\(playlist.name) has \(count) songs")
        }
    }

    @Test func playlistIDsLookLikeCatalogIDs() {
        #expect(data.playlists.allSatisfy { $0.id.rawValue.hasPrefix("pl.") })
        #expect(data.playlists.allSatisfy { $0.url?.lastPathComponent == $0.id.rawValue })
    }

    @Test func trackIDsAreUnique() {
        let ids = data.allTracks.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func titleAndArtistPairsAreUniqueBecauseFavoritesKeyOnThem() {
        let keys = data.allTracks.map { "\($0.title)||\($0.artistName)" }
        #expect(Set(keys).count == keys.count)
    }

    @Test func everySongHasADuration() {
        #expect(data.allTracks.allSatisfy { $0.duration >= 120 && $0.duration < 270 })
    }
}
