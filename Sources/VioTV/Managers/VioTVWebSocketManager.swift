import Foundation
import Combine

/// Manages the WebSocket connection to the Vio backend.
/// Publishes decoded ShoppableAdEvent when a `shoppable_ad` message arrives.
final class VioTVWebSocketManager: ObservableObject {
    @Published var lastShoppableAd: ShoppableAdEvent?

    private var webSocketTask: URLSessionWebSocketTask?
    private var currentUrlString: String?
    private var reconnectTask: Task<Void, Never>?

    func connect(to urlString: String) {
        currentUrlString = urlString
        openConnection(to: urlString)
    }

    private func openConnection(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        print("[VioTV] WebSocket connected to \(urlString)")
        receiveMessages()
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
                    print("[VioTV] WS raw: \(text.prefix(200))")
                    if let data = text.data(using: .utf8) {
                        do {
                            let event = try JSONDecoder().decode(ShoppableAdEvent.self, from: data)
                            if event.type == "shoppable_ad" {
                                DispatchQueue.main.async {
                                    self?.lastShoppableAd = event
                                    print("[VioTV] shoppable_ad received: \(event.product.title)")
                                }
                            }
                        } catch {
                            print("[VioTV] WS decode error: \(error)")
                        }
                    }
                }
                self?.receiveMessages()
            case .failure(let error):
                print("[VioTV] WS error: \(error)")
                self?.scheduleReconnect()
            }
        }
    }
}
