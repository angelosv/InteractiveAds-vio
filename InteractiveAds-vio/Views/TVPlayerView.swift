import SwiftUI

struct TVPlayerView: View {
    @StateObject private var videoViewModel = VideoPlayerViewModel()
    @StateObject private var wsManager = VioTVWebSocketManager.shared
    @State private var showShoppableCard = false
    @State private var commerceProduct: CommerceProduct?

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
                        onDismiss: { showShoppableCard = false }
                    )
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { showShoppableCard = false }
            }
        }
        .onAppear {
            let config = VioTVConfigLoader.shared.config!
            wsManager.connect(to: config.webSocketUrl)
        }
        .onReceive(wsManager.$lastShoppableAd) { event in
            guard let event = event, let productId = event.product?.id else { return }
            Task {
                if let fetched = await VioCommerceService.shared.fetchProduct(id: productId) {
                    await MainActor.run {
                        commerceProduct = fetched
                        withAnimation { showShoppableCard = true }
                    }
                }
            }
        }
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
        let url = URL(string: "\(config.backendUrl)/api/cart-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-Api-Key")
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
