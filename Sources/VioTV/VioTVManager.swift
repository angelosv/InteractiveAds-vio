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
}
