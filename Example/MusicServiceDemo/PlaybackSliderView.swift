import MusicService
import SwiftUI

struct PlaybackSliderView: View {
    @Environment(DemoModel.self) private var model
    let duration: TimeInterval

    @State private var scrubValue: Double?

    var body: some View {
        let player = model.player
        let shown = scrubValue ?? player.playbackTime

        VStack {
            Slider(
                value: Binding(get: { shown }, set: { scrubValue = $0 }),
                in: 0...max(duration, 1)
            ) { editing in
                if !editing, let value = scrubValue {
                    player.playbackTime = value
                    scrubValue = nil
                }
            }
            HStack {
                Text(Duration.seconds(Int(shown)), format: .time(pattern: .minuteSecond))
                Spacer()
                Text(Duration.seconds(-Int(max(duration - shown, 0))), format: .time(pattern: .minuteSecond))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
}
