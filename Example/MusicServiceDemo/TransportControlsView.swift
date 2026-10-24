import MusicService
import SwiftUI

struct TransportControlsView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        let player = model.player

        HStack {
            Button("Shuffle", systemImage: "shuffle") {
                model.toggleShuffle()
            }
            .foregroundStyle(player.shuffleMode == .songs ? Color.accentColor : .secondary)

            Spacer()

            Button("Previous", systemImage: "backward.fill") {
                Task { await model.skipToPrevious() }
            }

            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") {
                Task { await model.togglePlayPause() }
            }
            .font(.largeTitle)

            Button("Next", systemImage: "forward.fill") {
                Task { await model.skipToNext() }
            }

            Spacer()

            Button("Repeat", systemImage: player.repeatMode == .one ? "repeat.1" : "repeat") {
                model.cycleRepeat()
            }
            .foregroundStyle(player.repeatMode == .none ? .secondary : Color.accentColor)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .font(.title2)
        .padding(.horizontal)
    }
}
