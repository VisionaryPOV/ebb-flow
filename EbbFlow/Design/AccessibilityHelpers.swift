import SwiftUI

enum AccessibilityLabels {
    static func tideHeight(_ height: Double) -> String {
        String(format: "Tide height %.1f feet", height)
    }

    static func tideDirection(isRising: Bool) -> String {
        isRising ? "Rising tide" : "Falling tide"
    }

    static func extreme(_ extreme: TideExtreme) -> String {
        String(format: "%@ tide at %.1f feet", extreme.kind.label, extreme.height)
    }
}

extension View {
    func ebbFlowAccessibilityLabel(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isStaticText)
    }
}