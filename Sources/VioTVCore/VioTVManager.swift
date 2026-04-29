import Foundation
import Combine

@MainActor
public final class VioTVManager: ObservableObject {
    public static let shared = VioTVManager()

    @Published public var activeAd: ShoppableAdEvent?
    public var onCartIntent: ((String) -> Void)?
    /// Invoked when `POST /v2/tv/broadcast/subscribe` responds with
    /// `subscribed: false`. Host apps can opt in to log / surface the reason;
    /// by default the SDK stays silent so partners' apps never see errors
    /// from broadcasts that Vio simply doesn't know about.
    public var onSubscriptionFailed: ((VioTVSubscribeFailureReason) -> Void)?

    private let wsManager = VioTVWebSocketManager()
    private let session = VioTVSessionManager()
    private var cancellable: AnyCancellable?
    private var activePlatform: String = "apple-tv"

    private init() {
        cancellable = wsManager.$lastShoppableAd
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let event = event else { return }
                self?.activeAd = event
                print("[VioTV] Active ad updated: \(event.product.title) (activationId: \(event.activationId.map(String.init) ?? "-"))")
            }
    }

    /// Entry point for the host app. Performs the combined
    /// `/v2/tv/broadcast/subscribe` bootstrap; on success opens the WS
    /// and starts the heartbeat. On soft-miss (`subscribed: false`) the SDK
    /// stays quiet and only invokes ``onSubscriptionFailed`` if the host set it.
    public func connect(broadcastId: String, platform: String = "apple-tv", tvDeviceId: String? = nil) {
        activePlatform = platform
        Task { [weak self] in
            guard let self = self else { return }
            let outcome = await self.subscribe(broadcastId: broadcastId, platform: platform, tvDeviceId: tvDeviceId)
            switch outcome {
            case .subscribed(let response):
                VioTVConfiguration.shared.applySubscribeResponse(response)
                if let wsUrl = response.wsUrl {
                    self.wsManager.connect(to: wsUrl, identifyUserId: VioTVConfiguration.shared.userId)
                }
                if let sessionId = response.sessionId {
                    self.session.start(sessionId: sessionId)
                }
            case .softMiss(let reason):
                print("[VioTV] Subscribe soft-miss: \(reason.rawValue) — staying idle")
                self.onSubscriptionFailed?(reason)
            case .hardError(let message):
                print("[VioTV] Subscribe hard error: \(message)")
            }
        }
    }

    public func disconnect() {
        Task { [weak self] in
            guard let self = self else { return }
            if let sessionId = VioTVConfiguration.shared.currentSessionId {
                await self.session.end(sessionId: sessionId)
            }
            self.wsManager.disconnect()
            VioTVConfiguration.shared.clearSubscribeState()
            await MainActor.run { self.activeAd = nil }
        }
    }

    /// POSTs to the TV-specific cart-intent endpoint so the backend can:
    /// - persist `cart_intents` with `source_activation_id = activationId`
    /// - forward the envelope to the user's mobile device via WS / webhook / APNs.
    ///
    /// `activationId` and `sponsorId` are sourced from the current `activeAd`
    /// when not provided explicitly, closing the TV → Mobile attribution chain.
    public func sendCartIntent(
        productId: String,
        campaignId: Int,
        activationId: Int? = nil,
        sponsorId: Int? = nil
    ) async -> Bool {
        guard campaignId > 0 else {
            print("[VioTV] Invalid campaign id for cart-intent")
            return false
        }

        let config = VioTVConfiguration.shared
        let urlString = "\(config.backendURL)/v2/tv/cart-intent"
        guard let url = URL(string: urlString) else {
            print("[VioTV] Invalid cart-intent URL")
            return false
        }

        let resolvedActivation = activationId ?? activeAd?.activationId
        let resolvedSponsor = sponsorId ?? activeAd?.sponsorId ?? activeAd?.sponsor.flatMap { _ in nil }

        var body: [String: Any] = [
            "externalUserId": config.userId,
            "productId": productId,
            "campaignId": campaignId,
            "platform": activePlatform
        ]
        if let resolvedActivation { body["activationId"] = resolvedActivation }
        if let resolvedSponsor { body["sponsorId"] = resolvedSponsor }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("[VioTV] POST cart-intent to \(urlString) — activationId=\(resolvedActivation.map(String.init) ?? "-")")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            let isSuccess = (200...299).contains(status)
            print("[VioTV] Cart-intent response \(status): \(responseBody.prefix(200))")
            if isSuccess {
                onCartIntent?(productId)
            }
            return isSuccess
        } catch {
            print("[VioTV] Cart-intent error: \(error)")
            return false
        }
    }

    // MARK: - Internal — subscribe flow

    internal enum SubscribeOutcome {
        case subscribed(VioTVSubscribeResponse)
        case softMiss(VioTVSubscribeFailureReason)
        case hardError(String)
    }

    internal func subscribe(broadcastId: String, platform: String, tvDeviceId: String?) async -> SubscribeOutcome {
        let config = VioTVConfiguration.shared
        guard !config.apiKey.isEmpty else {
            return .hardError("VioTV not configured — call configure / configureFromBundle first")
        }

        let urlString = "\(config.backendURL)/v2/tv/broadcast/subscribe"
        guard let url = URL(string: urlString) else {
            return .hardError("Invalid subscribe URL: \(urlString)")
        }

        var body: [String: Any] = [
            "broadcastId": broadcastId,
            "externalUserId": config.userId,
            "platform": platform
        ]
        if let tvDeviceId { body["tvDeviceId"] = tvDeviceId }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 10
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200...299).contains(status) else {
                return .hardError("HTTP \(status)")
            }
            let decoded = try JSONDecoder().decode(VioTVSubscribeResponse.self, from: data)
            if decoded.subscribed {
                return .subscribed(decoded)
            }
            return .softMiss(VioTVSubscribeFailureReason(rawValue: decoded.reason ?? ""))
        } catch {
            return .hardError(error.localizedDescription)
        }
    }
}
