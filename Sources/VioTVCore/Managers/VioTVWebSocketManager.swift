import Foundation
import Combine

final class VioTVWebSocketManager: ObservableObject {
    @Published var lastShoppableAd: ShoppableAdEvent?

    private var webSocketTask: URLSessionWebSocketTask?
    private var currentUrlString: String?
    private var identifyUserId: String?
    private var reconnectTask: Task<Void, Never>?

    func connect(to urlString: String, identifyUserId: String?) {
        currentUrlString = urlString
        self.identifyUserId = identifyUserId
        openConnection(to: urlString)
    }

    private func openConnection(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("[VioTV] WebSocket connected to \(urlString)")
        sendIdentifyIfNeeded()
        receiveMessages()
    }

    private func sendPong() {
        let payload = ["type": "pong"]
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let text = String(data: data, encoding: .utf8)
        else { return }
        webSocketTask?.send(.string(text)) { error in
            if let error = error { print("[VioTV] WS pong send error: \(error)") }
        }
    }

    /// After the WS upgrades, announce which user this socket belongs to so the
    /// backend can route user-targeted events (e.g. cart_intent going to this
    /// user's mobile device) back through the same node via `wsUserMap`.
    private func sendIdentifyIfNeeded() {
        guard let userId = identifyUserId, !userId.isEmpty else { return }
        let payload = ["type": "identify", "userId": userId]
        guard
            let data = try? JSONSerialization.data(withJSONObject: payload),
            let text = String(data: data, encoding: .utf8)
        else { return }
        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error = error {
                print("[VioTV] WS identify send error: \(error)")
                _ = self
            }
        }
    }

    func disconnect() {
        reconnectTask?.cancel()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        currentUrlString = nil
    }

    private func scheduleReconnect() {
        guard let url = currentUrlString else { return }
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            print("[VioTV] Reconnecting WebSocket...")
            openConnection(to: url)
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.handleTextMessage(text)
                }
                self?.receiveMessages()
            case .failure(let error):
                print("[VioTV] WS error: \(error)")
                self?.scheduleReconnect()
            }
        }
    }

    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        do {
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = json["type"] as? String else { return }

            // App-level keep-alive: backend sends {"type":"ping"} every ~20s and closes the
            // socket after 3 unanswered ones. Reply with a pong instead of printing raw noise.
            if type == "ping" {
                sendPong()
                return
            }

            print("[VioTV] WS raw: \(text.prefix(200))")
            if type == "product" || type == "shoppable_ad" {
                if type == "shoppable_ad" {
                    let event = try JSONDecoder().decode(ShoppableAdEvent.self, from: data)
                    DispatchQueue.main.async {
                        self.lastShoppableAd = event
                        print("[VioTV] shoppable_ad received: \(event.product.title)")
                    }
                } else {
                    let event = try JSONDecoder().decode(BackendProductEvent.self, from: data)
                    let mapped = event.toShoppableAdEvent()
                    DispatchQueue.main.async {
                        self.lastShoppableAd = mapped
                        print("[VioTV] product event mapped -> shoppable_ad: \(mapped.product.title)")
                    }
                }
            }
        } catch {
            print("[VioTV] WS decode error: \(error)")
        }
    }
}
