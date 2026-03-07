import Foundation
import Combine

/// Central manager that owns the WebSocket connection and publishes active ad events.
@MainActor
public final class VioTVManager: ObservableObject {
    public static let shared = VioTVManager()

    @Published public var activeAd: ShoppableAdEvent?

    private let wsManager = VioTVWebSocketManager()
    private var cancellable: AnyCancellable?

    private init() {
        cancellable = wsManager.$lastShoppableAd
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let event = event else { return }
                // Second event replaces the first (no queue)
                self?.activeAd = event
                print("[VioTV] Active ad updated: \(event.product.title)")
            }
    }

    func connect(to urlString: String) {
        wsManager.connect(to: urlString)
    }

    func disconnect() {
        wsManager.disconnect()
        activeAd = nil
    }

    /// Send a cart-intent to the backend for the given product.
    /// On success, invokes VioTV.onCartIntent with the product ID.
    public func sendCartIntent(productId: String, campaignId: Int) {
        let config = VioTVConfiguration.shared
        let urlString = "\(config.environment.backendURL)/api/campaigns/\(campaignId)/cart-intent"
        guard let url = URL(string: urlString) else {
            print("[VioTV] Invalid cart-intent URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "productId": productId,
            "userId": config.userId
        ])

        Task {
            print("[VioTV] POST cart-intent to \(urlString)")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let body = String(data: data, encoding: .utf8) ?? ""
                print("[VioTV] Cart-intent response \(status): \(body.prefix(200))")
            } catch {
                print("[VioTV] Cart-intent error: \(error)")
            }
            VioTV.onCartIntent?(productId)
        }
    }
}
