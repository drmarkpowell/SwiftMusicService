import MusicService
import SwiftUI

/// Debug controls for the mock. Hidden when the app is running against live MusicKit.
struct BehaviorScreen: View {
    @Environment(DemoModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                if let mock = model.service as? MockMusicService {
                    MockControlsView(mock: mock)
                } else {
                    ContentUnavailableView(
                        "Live MusicKit",
                        systemImage: "music.note",
                        description: Text(
                            "Behavior controls only apply to the mock. Launch with -MusicServiceUseMock to see them."
                        )
                    )
                }
            }
            .navigationTitle("Behavior")
        }
    }
}

private struct MockControlsView: View {
    let mock: MockMusicService

    @State private var latency = LatencyChoice.quick
    @State private var speed = SpeedChoice.normal

    var body: some View {
        let behavior = mock.behavior

        Form {
            Section("Timing") {
                Picker("Latency", selection: $latency) {
                    ForEach(LatencyChoice.allCases) { Text($0.title).tag($0) }
                }
                Picker("Playback speed", selection: $speed) {
                    ForEach(SpeedChoice.allCases) { Text($0.title).tag($0) }
                }
            }

            Section("Authorization") {
                Picker("Status", selection: Binding(
                    get: { mock.mockAuthorization.currentStatus },
                    set: { mock.mockAuthorization.setStatus($0) }
                )) {
                    Text("Not determined").tag(MusicAuthorizationStatus.notDetermined)
                    Text("Authorized").tag(MusicAuthorizationStatus.authorized)
                    Text("Denied").tag(MusicAuthorizationStatus.denied)
                    Text("Restricted").tag(MusicAuthorizationStatus.restricted)
                }
            }

            Section("Fail these operations") {
                ForEach(MockFailure.allCases, id: \.self) { failure in
                    Toggle(failure.rawValue, isOn: Binding(
                        get: { behavior.failures.contains(failure) },
                        set: { isOn in
                            if isOn { behavior.failures.insert(failure) } else { behavior.failures.remove(failure) }
                        }
                    ))
                }
            }

            Section("Player") {
                Button("Jump to 3 seconds before the end") {
                    let duration = mock.mockPlayer.currentEntry?.duration ?? 0
                    mock.mockPlayer.playbackTime = max(duration - 3, 0)
                }
                .disabled(mock.mockPlayer.currentEntry == nil)

                Button("Simulate playback stall") {
                    mock.mockPlayer.simulateStall()
                }
            }
        }
        .onChange(of: latency) {
            behavior.latency = latency.duration
        }
        .onChange(of: speed) {
            behavior.playbackSpeed = speed.factor
        }
    }
}

private enum LatencyChoice: CaseIterable, Identifiable {
    case instant, quick, slow, hang

    var id: Self { self }

    var title: String {
        switch self {
        case .instant: "Instant"
        case .quick: "0.2 s"
        case .slow: "3 s"
        case .hang: "30 s (exceeds DJ Mood's 7 s timeout)"
        }
    }

    var duration: Duration {
        switch self {
        case .instant: .zero
        case .quick: .milliseconds(200)
        case .slow: .seconds(3)
        case .hang: .seconds(30)
        }
    }
}

private enum SpeedChoice: CaseIterable, Identifiable {
    case normal, fast, veryFast

    var id: Self { self }

    var title: String {
        switch self {
        case .normal: "1×"
        case .fast: "10×"
        case .veryFast: "60×"
        }
    }

    var factor: Double {
        switch self {
        case .normal: 1
        case .fast: 10
        case .veryFast: 60
        }
    }
}
