import SwiftUI

struct TVPlayerView: View {
    @StateObject private var videoViewModel = VideoPlayerViewModel()
    @StateObject private var wsManager = VioTVWebSocketManager.shared
    @State private var showShoppableCard = false
    @State private var commerceProduct: CommerceProduct?
    @State private var dismissWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video Background
            if let videoURL = VideoConfig.getVideoURL() {
                VideoPlayerView(videoURL: videoURL, viewModel: videoViewModel)
                    .ignoresSafeArea()

                // Dark overlay to make content readable
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                // Video controls overlay — estilo referencia, ocultar tras 3s
                VideoControlsOverlay(viewModel: videoViewModel)
                    .ignoresSafeArea(edges: .bottom)

                // Shoppable product card — encima de controles para que Add to cart sea visible
                if showShoppableCard, let product = commerceProduct {
                    TVShoppableOverlay(
                        product: product,
                        onAddToCart: { sendCartIntent(productId: product.id) },
                        onDismiss: { withAnimation(.easeOut(duration: 0.35)) { showShoppableCard = false } }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                }
            } else {
                // Fallback gradient if video fails
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .tvCartIntentSent)) { _ in
            dismissWorkItem?.cancel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showShoppableCard = false }
            }
        }
        .onAppear {
            guard let config = VioTVConfigLoader.shared.config else {
                print("❌ [VioTV] config no cargado — asegúrate de llamar VioTVConfigLoader.shared.load()")
                // Fallback directo
                wsManager.connect(to: "wss://api-dev.vio.live/ws/36")
                return
            }
            print("✅ [VioTV] conectando a \(config.webSocketUrl)")
            wsManager.connect(to: config.webSocketUrl)
        }
        .onReceive(wsManager.$lastShoppableAd) { event in
            guard let event = event, let tvProduct = event.product else { return }
            // Usar los datos del WS directamente (ya resueltos por el backend)
            // Construimos via JSON para evitar problemas con custom init
            let dict: [String: Any] = [
                "id": tvProduct.id,
                "title": tvProduct.name,
                "images": tvProduct.imageUrl.map { [["url": $0, "order": 0]] } ?? [],
                "price": ["amount": tvProduct.price, "amount_incl_taxes": tvProduct.price, "currency_code": tvProduct.currency]
            ]
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let product = try? JSONDecoder().decode(CommerceProduct.self, from: data) {
                dismissWorkItem?.cancel()
                commerceProduct = product
                withAnimation(.easeOut(duration: 0.4)) { showShoppableCard = true }
                print("✅ [VioTV] Mostrando card: \(product.name)")
                // Desaparece automáticamente tras 15 segundos
                let work = DispatchWorkItem {
                    withAnimation(.easeIn(duration: 0.35)) { showShoppableCard = false }
                }
                dismissWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 15, execute: work)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showShoppableCard)
    }

    private func loadProduct() {
        guard let productId = VioTVConfigLoader.shared.staticData?.demoProducts.first?.id else { return }
        Task {
            if let product = await VioCommerceService.shared.fetchProduct(id: productId) {
                await MainActor.run {
                    commerceProduct = product
                }
            }
        }
    }

    private func sendCartIntent(productId: String) {
        let config = VioTVConfigLoader.shared.config!
        let url = URL(string: "\(config.backendUrl)/api/campaigns/\(config.campaignId)/cart-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "userId": "angelo_demo_001",
            "campaignId": config.campaignId,
            "productId": productId,
        ])
        Task {
            _ = try? await URLSession.shared.data(for: request)
            await MainActor.run {
                NotificationCenter.default.post(name: .tvCartIntentSent, object: nil)
            }
        }
    }
}
