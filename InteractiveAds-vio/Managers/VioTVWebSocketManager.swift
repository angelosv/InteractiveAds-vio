import Foundation
import Combine

class VioTVWebSocketManager: ObservableObject {
    static let shared = VioTVWebSocketManager()

    @Published var lastShoppableAd: ShoppableAdEvent? = nil

    private var webSocketTask: URLSessionWebSocketTask?
    private var isConnected = false

    func connect(to urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        print("🔌 [VioTV] WebSocket conectado a \(urlString)")
        receiveMessages()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message,
                   let data = text.data(using: .utf8),
                   let event = try? JSONDecoder().decode(ShoppableAdEvent.self, from: data),
                   event.type == "shoppable_ad" {
                    DispatchQueue.main.async {
                        self?.lastShoppableAd = event
                        print("📺 [VioTV] shoppable_ad recibido: \(event.product?.name ?? "?")")
                    }
                }
                self?.receiveMessages()
            case .failure(let error):
                print("❌ [VioTV] WS error: \(error)")
            }
        }
    }

    /// Simula un evento shoppable_ad localmente (para demo sin backend)
    func simulateShoppableAd(product: TVProduct, sponsor: TVSponsor) {
        let event = ShoppableAdEvent(type: "shoppable_ad", product: product, sponsor: sponsor)
        DispatchQueue.main.async {
            self.lastShoppableAd = event
        }
    }
}
