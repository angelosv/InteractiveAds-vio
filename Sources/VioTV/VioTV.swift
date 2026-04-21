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

    public static func configure(
        apiKey: String,
        commerceApiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development,
        defaultCampaignId: Int? = nil
    ) {
        VioTVConfiguration.shared.configure(
            apiKey: apiKey,
            commerceApiKey: commerceApiKey,
            userId: userId,
            environment: environment,
            defaultCampaignId: defaultCampaignId
        )
        setupCommerceEnrichment()
    }

    public static func configureFromBundle(
        fileName: String? = nil,
        bundle: Bundle = .main,
        userIdOverride: String? = nil
    ) throws {
        let config = try VioTVConfigurationLoader.loadConfiguration(fileName: fileName, bundle: bundle)
        let environment = VioTVEnvironment(rawValue: (config.environment ?? "development").lowercased()) ?? .development
        configure(
            apiKey: config.apiKey,
            commerceApiKey: config.commerceApiKey,
            userId: userIdOverride ?? config.userId ?? "",
            environment: environment,
            defaultCampaignId: config.campaignId
        )
    }

    public static func connect(broadcastId: String) {
        VioTVManager.shared.connect(broadcastId: broadcastId)
    }

    public static func connect() {
        guard let campaignId = VioTVConfiguration.shared.defaultCampaignId else {
            print("[VioTV] Missing default campaignId. Call configure(defaultCampaignId:) or connect(broadcastId:).")
            return
        }
        connect(broadcastId: String(campaignId))
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
                    guard let enrichedProduct = await VioTVCommerceService.shared.fetchProduct(id: event.product.id) else {
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
