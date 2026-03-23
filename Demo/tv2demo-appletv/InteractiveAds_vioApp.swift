import SwiftUI
import VioTV

@main
struct InteractiveAds_vioApp: App {
    init() {
        // Load config from bundle JSON
        guard let url = Bundle.main.url(forResource: "vio-config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(DemoConfig.self, from: data) else {
            fatalError("[Demo] Failed to load vio-config.json")
        }

        VioTV.configure(
            apiKey: config.apiKey,
            commerceApiKey: config.commerceApiKey,
            userId: "demo_user_001",
            environment: .development
        )

        VioTV.onCartIntent = { productId in
            print("[Demo] Cart intent sent for product: \(productId)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Minimal config struct for the demo app's vio-config.json.
struct DemoConfig: Codable {
    let apiKey: String
    let commerceApiKey: String
    let campaignId: Int
    let contentId: String
    let country: String
}
