import MusicService
import SwiftUI

struct BrowseScreen: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Group {
                if model.authorizationStatus != .authorized {
                    AuthorizationPromptView()
                } else {
                    PlaylistListView()
                }
            }
            .navigationTitle("Browse")
            .searchable(text: $model.searchText, prompt: "Search playlists")
            .onSubmit(of: .search) {
                Task { await model.search() }
            }
            .task(id: model.authorizationStatus) {
                if model.authorizationStatus == .authorized { await model.search() }
            }
        }
    }
}

private struct PlaylistListView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        List(model.playlists) { playlist in
            Button {
                Task { await model.play(playlist) }
            } label: {
                HStack {
                    MusicArtworkView(playlist.artwork, size: 48)
                    VStack(alignment: .leading) {
                        Text(playlist.name)
                        if let curator = playlist.curatorName {
                            Text(curator)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            } else if model.playlists.isEmpty {
                ContentUnavailableView(
                    "No Playlists",
                    systemImage: "music.note.list",
                    description: Text(
                        model.usingMock ? "Pull to refresh or clear the search." : "Search for a playlist."
                    )
                )
            }
        }
        .refreshable {
            await model.search()
        }
    }
}

private struct AuthorizationPromptView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        ContentUnavailableView {
            Label("Apple Music Access", systemImage: "lock")
        } description: {
            Text(description)
        } actions: {
            Button("Connect Apple Music") {
                Task { await model.requestAuthorization() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var description: String {
        switch model.authorizationStatus {
        case .denied: "Access was denied. Change it in Settings, or reset the mock's status on the Behavior tab."
        case .restricted: "Access is restricted on this device."
        default: "Connect to browse and play playlists."
        }
    }
}
