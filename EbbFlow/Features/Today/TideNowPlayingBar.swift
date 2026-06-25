import SwiftUI

struct TideNowPlayingBar: View {
    let stationName: String
    let state: TideCurrentState
    let timeZone: TimeZone

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.isRising ? "arrow.up.right" : "arrow.down.right")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(stationName)
                    .font(.subheadline.weight(.semibold))
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "%.1f ft", state.height))
                .font(.title3.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statusLine: String {
        let direction = state.isRising ? "Rising" : "Falling"
        if let next = state.nextExtreme {
            let time = TideDataTransformer.formatShortTime(next.time, timeZone: timeZone)
            return "\(direction) · \(next.kind.label) at \(time)"
        }
        return direction
    }
}