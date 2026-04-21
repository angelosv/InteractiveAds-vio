import SwiftUI
import VioTV

@main
struct InteractiveAds_vioApp: App {
    init() {
        do {
            try VioTV.configureFromBundle(userIdOverride: "demo_user_001")
        } catch {
            fatalError("[Demo] Failed to configure VioTV from bundle: \(error)")
        }

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
