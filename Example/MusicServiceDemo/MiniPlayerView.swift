import MusicService
import SwiftUI

struct MiniPlayerView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        let player = model.player

        HStack {
            MusicArtworkView(player.currentEntry?.artwork, size: 32)
            Text(player.currentEntry?.title ?? "")
                .lineLimit(1)
            Spacer()
            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") {
                Task { await model.togglePlayPause() }
            }
            .labelStyle(.iconOnly)
            Button("Next", systemImage: "forward.fill") {
                Task { await model.skipToNext() }
            }
            .labelStyle(.iconOnly)
        }
        .padding(.horizontal)
    }
}
