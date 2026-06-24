import Foundation
import StoreKit

enum ProFeature: String, CaseIterable, Sendable {
    case unlimitedSpots
    case monthlyCharts
    case journalSync
    case liveActivities
    case export
}

@MainActor
@Observable
final class StoreKitManager {
    static let monthlyProductID = "com.ebbflow.pro.monthly"
    static let yearlyProductID = "com.ebbflow.pro.yearly"

    var isProUser = false
    var products: [Product] = []

    func loadProducts() async {
        do {
            products = try await Product.products(for: [Self.monthlyProductID, Self.yearlyProductID])
        } catch {
            products = []
        }
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified = verification {
                isProUser = true
            }
        default:
            break
        }
    }

    func canAccess(_ feature: ProFeature) -> Bool {
        switch feature {
        case .unlimitedSpots, .monthlyCharts, .journalSync, .liveActivities, .export:
            isProUser
        }
    }

    static func featureLabel(_ feature: ProFeature) -> String {
        switch feature {
        case .unlimitedSpots: "Unlimited favorite spots"
        case .monthlyCharts: "Monthly tide charts"
        case .journalSync: "Journal sync"
        case .liveActivities: "Live Activities"
        case .export: "CSV and PDF export"
        }
    }
}