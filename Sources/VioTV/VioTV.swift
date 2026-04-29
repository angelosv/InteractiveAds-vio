import Foundation
import Combine
@_exported import VioTVUI
@_exported import VioTVCore
import VioTVCommerce

/// Public entry point for the VioTV SDK.
@MainActor
public enum VioTV {
    private static var activeAdCancellable: AnyCancellable?

    public static var onCartIntent: ((String) -> Void)? {
        get { VioTVManager.shared.onCartIntent }
        set { VioTVManager.shared.onCartIntent = newValue }
    }

    /// Invoked when `POST /v2/tv/broadcast/subscribe` responds
    /// `{ subscribed: false, reason }`. Set this if the host app wants to log
    /// or react when Vio doesn't recognise the partner-provided broadcastId.
    /// Default: nil (SDK stays silent — host sees no error).
    public static var onSubscriptionFailed: ((VioTVSubscribeFailureReason) -> Void)? {
        get { VioTVManager.shared.onSubscriptionFailed }
        set { VioTVManager.shared.onSubscriptionFailed = newValue }
    }

    public static func configure(
        apiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development
    ) {
        VioTVConfiguration.shared.configure(
            apiKey: apiKey,
            userId: userId,
            environment: environment
        )
        setupCommerceEnrichment()
    }

    public static func configureFromBundle(
        fileName: String? = nil,
        bundle: Bundle = .main,
        userIdOverride: String? = nil
    ) throws {
        let config = try VioTVConfigurationLoader.loadConfiguration(fileName: fileName, bundle: bundle)
        VioTVConfiguration.shared.applyFileConfiguration(config, userIdOverride: userIdOverride)
        setupCommerceEnrichment()
    }

    /// Entry point once the host app knows which broadcast is playing.
    /// The SDK performs `POST /v2/tv/broadcast/subscribe`. On success:
    /// opens the WebSocket, sends the identify message, and starts a 60s
    /// session heartbeat. On soft-miss the SDK stays idle — the host sees
    /// nothing unless it set `onSubscriptionFailed`.
    ///
    /// `broadcastId` is required — there is no zero-arg `connect()`. The
    /// host app always knows which broadcast is playing; the SDK never
    /// guesses from local config.
    public static func connect(broadcastId: String, platform: String = "apple-tv", tvDeviceId: String? = nil) {
        VioTVManager.shared.connect(broadcastId: broadcastId, platform: platform, tvDeviceId: tvDeviceId)
    }

    public static func disconnect() {
        VioTVManager.shared.disconnect()
    }

    private static func setupCommerceEnrichment() {
        activeAdCancellable = VioTVManager.shared.$activeAd
            .compactMap { $0 }
            .sink { event in
                guard shouldEnrichFromCommerce(event: event) else { return }
                Task {
                    // Route to the correct sponsor's commerce key using sponsorId on the event.
                    let commerceKey = VioTVConfiguration.shared.commerce(forSponsorId: event.sponsorId)?.apiKey
                    guard let enrichedProduct = await VioTVCommerceService.shared.fetchProduct(
                        id: event.product.id,
                        commerceApiKey: commerceKey
                    ) else {
                        return
                    }
                    await MainActor.run {
                        VioTVManager.shared.activeAd = event.withProduct(enrichedProduct)
                    }
                }
            }
    }

    private static func shouldEnrichFromCommerce(event: ShoppableAdEvent) -> Bool {
        event.product.images.isEmpty || event.product.title.isEmpty || event.product.price.amount <= 0
    }
}
