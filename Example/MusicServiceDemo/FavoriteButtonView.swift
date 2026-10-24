import MusicService
import SwiftUI

struct FavoriteButtonView: View {
    @Environment(DemoModel.self) private var model
    let track: MusicTrack

    var body: some View {
        let isFavorite = model.isFavorite(track)
        Button(
            isFavorite ? "Remove Favorite" : "Add Favorite",
            systemImage: isFavorite ? "heart.fill" : "heart"
        ) {
            Task { await model.toggleFavorite(track) }
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(isFavorite ? .red : .secondary)
        .buttonStyle(.plain)
        .font(.title2)
    }
}
