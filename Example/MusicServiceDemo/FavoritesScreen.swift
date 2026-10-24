import MusicService
import SwiftUI

struct FavoritesScreen: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        NavigationStack {
            List(model.favorites) { track in
                HStack {
                    MusicArtworkView(track.artwork, size: 40)
                    VStack(alignment: .leading) {
                        Text(track.title)
                        Text(track.artistName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    FavoriteButtonView(track: track)
                }
            }
            .overlay {
                if model.favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites",
                        systemImage: "heart",
                        description: Text("Tap the heart on the Now Playing tab.")
                    )
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                Button("Play Favorites", systemImage: "play.fill") {
                    Task { await model.playFavorites() }
                }
                .disabled(model.favorites.isEmpty)
            }
            .task {
                await model.loadFavorites()
            }
        }
    }
}
