import MusicService
import SwiftUI

struct RootView: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        @Bindable var model = model

        TabView {
            Tab("Browse", systemImage: "square.grid.2x2") {
                BrowseScreen()
            }
            Tab("Now Playing", systemImage: "play.circle") {
                NowPlayingScreen()
            }
            Tab("Favorites", systemImage: "heart") {
                FavoritesScreen()
            }
            Tab("Behavior", systemImage: "slider.horizontal.3") {
                BehaviorScreen()
            }
        }
        .tabViewBottomAccessory(isEnabled: model.player.currentEntry != nil) {
            MiniPlayerView()
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}
