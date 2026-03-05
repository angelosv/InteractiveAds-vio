import Foundation
import Combine

class VioTVWebSocketManager: ObservableObject {
    static let shared = VioTVWebSocketManager()

    @Published var lastShoppableAd: ShoppableAdEvent? = nil

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
        print("🔌 [VioTV] WebSocket conectado a \(urlString)")
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
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
            guard !Task.isCancelled else { return }
            print("🔄 [VioTV] Reconectando WS...")
            openConnection(to: url)
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    print("📡 [VioTV] WS raw: \(text.prefix(200))")
                    if let data = text.data(using: .utf8) {
                        do {
                            let event = try JSONDecoder().decode(ShoppableAdEvent.self, from: data)
                            if event.type == "shoppable_ad" {
                                DispatchQueue.main.async {
                                    self?.lastShoppableAd = event
                                    print("📺 [VioTV] shoppable_ad OK: \(event.product?.name ?? "?")")
                                }
                            }
                        } catch {
                            print("❌ [VioTV] decode error: \(error)")
                        }
                    }
                }
                self?.receiveMessages()
            case .failure(let error):
                print("❌ [VioTV] WS error: \(error)")
                self?.scheduleReconnect()
            }
        }
    }

    func simulateShoppableAd(product: TVProduct, sponsor: TVSponsor) {
        let event = ShoppableAdEvent(type: "shoppable_ad", product: product, sponsor: sponsor)
        DispatchQueue.main.async { self.lastShoppableAd = event }
    }
}
