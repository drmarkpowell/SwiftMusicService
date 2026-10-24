import MusicService
import MusicServiceLive
import SwiftUI

@main
struct MusicServiceDemoApp: App {
    /// The simulator gets the mock and a device gets MusicKit. Launch with `-MusicServiceUseMock`
    /// or `-MusicServiceUseLive` to override.
    @State private var model = DemoModel(service: MusicServiceFactory.makeDefault())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
