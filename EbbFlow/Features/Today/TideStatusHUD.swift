import SwiftUI

struct TideStatusHUD: View {
    let state: TideCurrentState
    @Namespace private var glassNamespace
    @State private var expanded = false

    var body: some View {
        GlassEffectContainer(spacing: 24) {
            if expanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.isRising ? "Rising" : "Falling gently")
                        .font(.headline)
                    if let next = state.nextExtreme {
                        Text("\(next.kind.label) at \(formattedTime(next.time))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1f ft", state.height))
                        .font(.title3.monospacedDigit())
                }
                .padding()
                .glassEffect()
                .glassEffectID("tideHUD", in: glassNamespace)
                .onTapGesture {
                    withAnimation(.bouncy) { expanded = false }
                }
            } else {
                Label(
                    state.isRising ? "Rising" : "Falling",
                    systemImage: state.isRising ? "arrow.up" : "arrow.down"
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(.cyan))
                .glassEffectID("tideHUD", in: glassNamespace)
                .onTapGesture {
                    withAnimation(.bouncy) { expanded = true }
                }
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}