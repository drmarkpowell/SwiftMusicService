import MusicService
import SwiftUI

struct NowPlayingScreen: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if let entry = model.player.currentEntry {
                    NowPlayingContentView(entry: entry)
                } else if model.player.playbackStatus == .playing {
                    // The queue lost its current entry while playing: the stall MusicKit can produce.
                    ContentUnavailableView {
                        Label("Playback Stalled", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("The queue lost its current song.")
                    } actions: {
                        Button("Resume") {
                            Task { await model.togglePlayPause() }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Nothing Playing",
                        systemImage: "music.note",
                        description: Text("Pick a playlist on the Browse tab.")
                    )
                }
            }
            .navigationTitle("Now Playing")
        }
    }
}

private struct NowPlayingContentView: View {
    @Environment(DemoModel.self) private var model
    let entry: QueueEntry

    var body: some View {
        VStack {
            HStack {
                MusicArtworkView(entry.artwork, size: 112)
                VStack(alignment: .leading) {
                    Text(entry.title)
                        .bold()
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let track = entry.track {
                    FavoriteButtonView(track: track)
                }
            }
            .padding(.horizontal)

            PlaybackSliderView(duration: entry.duration)
                .padding(.horizontal)
            TransportControlsView()
            QueueListView()
        }
    }
}
