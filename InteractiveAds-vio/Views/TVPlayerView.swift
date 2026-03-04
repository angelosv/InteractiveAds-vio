import SwiftUI

struct TVPlayerView: View {
    let match: TVMatch
    let sponsor: TVSponsor
    let products: [TVProduct]

    @StateObject private var wsManager = VioTVWebSocketManager.shared
    @State private var commerceProduct: CommerceProduct? = nil
    @State private var showCard = false
    @FocusState private var isSimulateButtonFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Elkjøp ad
                VStack(spacing: 16) {
                    AsyncImage(url: URL(string: sponsor.logoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fit)
                        } else { EmptyView() }
                    }
                    .frame(height: 60)

                    Text("Norges største elektronikkjede")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Kampanje — opptil 40% rabatt")
                        .font(.system(size: 22))
                        .foregroundColor(.yellow)
                }

                Spacer()

                scoreBar

                Button(action: simulateAd) {
                    Text("▶ Simular anuncio Elkjøp")
                        .font(.system(size: 16))
                        .foregroundColor(isSimulateButtonFocused ? .yellow : .white.opacity(0.3))
                }
                .focused($isSimulateButtonFocused)
                .padding(.bottom, 24)
            }

            // Product card — esquina inferior izquierda
            if showCard, let product = commerceProduct {
                TVProductCard(product: product, sponsor: sponsor)
                    .padding(.leading, 60)
                    .padding(.bottom, 80)
            }
        }
        .onReceive(wsManager.$lastShoppableAd) { event in
            guard let event = event else { return }
            let productId = event.product?.id ?? products.first?.id ?? "408895"
            Task {
                if let fetched = await VioCommerceService.shared.fetchProduct(id: productId) {
                    await MainActor.run {
                        commerceProduct = fetched
                        withAnimation { showCard = true }
                        // Auto-dismiss a los 15s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                            withAnimation { showCard = false }
                        }
                    }
                }
            }
        }
        .onAppear {
            let config = VioTVConfigLoader.shared.config!
            wsManager.connect(to: config.webSocketUrl)
        }
    }

    private var scoreBar: some View {
        HStack(spacing: 40) {
            VStack {
                Text(match.homeTeam)
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("\(match.homeScore)")
                    .font(.system(size: 48, weight: .heavy)).foregroundColor(.white)
            }
            VStack(spacing: 4) {
                Text("\(match.minute)'")
                    .font(.system(size: 18, weight: .medium)).foregroundColor(.yellow)
                Text(match.period).font(.caption).foregroundColor(.white.opacity(0.6))
                Text("PAUSE")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.red)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.red.opacity(0.2)).clipShape(Capsule())
            }
            VStack {
                Text(match.awayTeam)
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("\(match.awayScore)")
                    .font(.system(size: 48, weight: .heavy)).foregroundColor(.white)
            }
        }
        .padding(.vertical, 24).padding(.horizontal, 48)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 16)
    }

    private func simulateAd() {
        let product = products.first!
        wsManager.simulateShoppableAd(product: product, sponsor: sponsor)
    }
}
