import StoreKit
import SwiftUI

struct MoreView: View {
    @Bindable var storeManager: StoreKitManager

    var body: some View {
        List {
            Section("Ebb & Flow Pro") {
                if storeManager.isProUser {
                    Label("Pro active", systemImage: "checkmark.seal.fill")
                } else {
                    ForEach(storeManager.products, id: \.id) { product in
                        Button {
                            Task { try? await storeManager.purchase(product) }
                        } label: {
                            Text("\(product.displayName) — \(product.displayPrice)")
                        }
                    }
                }
                ForEach(ProFeature.allCases, id: \.self) { feature in
                    Label(
                        StoreKitManager.featureLabel(feature),
                        systemImage: storeManager.canAccess(feature) ? "checkmark.circle" : "lock"
                    )
                }
            }
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Data Source", value: "NOAA CO-OPS + WorldTides fallback")
            }
            Section("Disclaimer") {
                Text("Tide predictions are for informational purposes only — not for navigation.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Tide predictions disclaimer")
            }
        }
        .navigationTitle("More")
        .task { await storeManager.loadProducts() }
    }
}