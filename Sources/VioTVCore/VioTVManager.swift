import Foundation
import Combine

@MainActor
public final class VioTVManager: ObservableObject {
    public static let shared = VioTVManager()

    @Published public var activeAd: ShoppableAdEvent?
    public var onCartIntent: ((String) -> Void)?

    private let wsManager = VioTVWebSocketManager()
    private var cancellable: AnyCancellable?

    private init() {
        cancellable = wsManager.$lastShoppableAd
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let event = event else { return }
                self?.activeAd = event
                print("[VioTV] Active ad updated: \(event.product.title)")
            }
    }

    public func connect(broadcastId: String) {
        let urlString = "\(VioTVConfiguration.shared.webSocketBaseURL)/\(broadcastId)"
        wsManager.connect(to: urlString)
    }

    public func disconnect() {
        wsManager.disconnect()
        activeAd = nil
    }

    public func sendCartIntent(productId: String, campaignId: Int) async -> Bool {
        guard campaignId > 0 else {
            print("[VioTV] Invalid campaign id for cart-intent")
            return false
        }

        let config = VioTVConfiguration.shared
        let urlString = "\(config.environment.backendURL)/api/campaigns/\(campaignId)/cart-intent"
        guard let url = URL(string: urlString) else {
            print("[VioTV] Invalid cart-intent URL")
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "productId": productId,
            "userId": config.userId
        ])

        print("[VioTV] POST cart-intent to \(urlString)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? ""
            let isSuccess = (200...299).contains(status)
            print("[VioTV] Cart-intent response \(status): \(body.prefix(200))")
            if isSuccess {
                onCartIntent?(productId)
            }
            return isSuccess
        } catch {
            print("[VioTV] Cart-intent error: \(error)")
            return false
        }
    }
}
