import Foundation

/// Public entry point for the VioTV SDK.
public enum VioTV {
    /// Callback invoked when a cart-intent is successfully sent for a product.
    public static var onCartIntent: ((String) -> Void)?

    /// Configure the SDK with credentials and environment.
    /// Call this once at app launch before using any other VioTV API.
    public static func configure(
        apiKey: String,
        commerceApiKey: String,
        userId: String = "",
        environment: VioTVEnvironment = .development
    ) {
        VioTVConfiguration.shared.configure(
            apiKey: apiKey,
            commerceApiKey: commerceApiKey,
            userId: userId,
            environment: environment
        )
    }

    /// Connect to the WebSocket for a given broadcast.
    public static func connect(broadcastId: String) {
        let url = "\(VioTVConfiguration.shared.webSocketBaseURL)/\(broadcastId)"
        VioTVManager.shared.connect(to: url)
    }

    /// Disconnect from the current WebSocket session.
    public static func disconnect() {
        VioTVManager.shared.disconnect()
    }
}
