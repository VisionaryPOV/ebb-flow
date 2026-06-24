import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Data Source", value: "NOAA CO-OPS")
            }
            Section("Disclaimer") {
                Text("Tide predictions are for informational purposes only — not for navigation. Always verify conditions on the water.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("More")
    }
}