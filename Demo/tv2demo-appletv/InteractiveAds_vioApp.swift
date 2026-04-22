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

        // Fires when the backend responds to /api/sdk/tv/broadcast/subscribe
        // with `{ subscribed: false, reason: ... }` — used by the picker to
        // visualise the "unknown broadcast" path.
        VioTV.onSubscriptionFailed = { reason in
            print("[Demo] Subscribe soft-miss: \(reason.rawValue) — SDK stays idle, no overlay will render")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
