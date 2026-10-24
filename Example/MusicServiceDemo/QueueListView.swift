import MusicService
import SwiftUI

struct QueueListView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        let player = model.player

        List(player.entries) { entry in
            let isCurrent = entry.id == player.currentEntry?.id
            Button {
                Task { await model.skip(to: entry) }
            } label: {
                HStack {
                    MusicArtworkView(entry.artwork, size: 40)
                    VStack(alignment: .leading) {
                        Text(entry.title)
                            .bold(isCurrent)
                        if let subtitle = entry.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if isCurrent {
                        Image(systemName: "waveform")
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Now playing")
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(isCurrent ? Color.accentColor.opacity(0.1) : nil)
        }
        .listStyle(.plain)
    }
}
