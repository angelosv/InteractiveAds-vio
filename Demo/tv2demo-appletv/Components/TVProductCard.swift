import SwiftUI

/// Card de producto en esquina inferior izquierda — datos de Commerce Vio
struct TVProductCard: View {
    let product: CommerceProduct
    let sponsor: TVSponsor

    @State private var appeared = false
    @State private var isLoading = false
    @State private var sentToPhone = false
    @FocusState private var isFocused: Bool

    private let userId = "angelo_demo_001"
    private let apiKey = "tv2_api_key_91b4fbf634af4bc5"
    private let backendUrl = "https://api-dev.vio.live"
    private let campaignId = 36

    var body: some View {
        HStack(spacing: 0) {
            // Imagen producto
            AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Color.white.opacity(0.08))
                        .overlay(Image(systemName: "shippingbox").foregroundColor(.white.opacity(0.3)))
                }
            }
            .frame(width: 160, height: 120)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 8) {
                // Sponsor logo
                HStack {
                    AsyncImage(url: URL(string: sponsor.logoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fit)
                        } else { EmptyView() }
                    }
                    .frame(height: 18)
                    Spacer()
                }

                Text(product.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(product.formattedPrice)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.yellow)

                // CTA
                Button(action: addToCart) {
                    Group {
                        if sentToPhone {
                            Label("Sendt til din mobil", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        } else if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Legg i handlekurv")
                                .foregroundColor(isFocused ? .black : .white)
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        sentToPhone ? Color.green :
                        isFocused ? Color.yellow : Color.white.opacity(0.15)
                    )
                    .clipShape(Capsule())
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                    .animation(.spring(response: 0.25), value: isFocused)
                }
                .focused($isFocused)
                .disabled(isLoading || sentToPhone)
            }
            .padding(16)
        }
        .frame(width: 420, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.12).opacity(0.95))
                .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 4)
        )
        .offset(y: appeared ? 0 : 60)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
        .onAppear {
            appeared = true
            isFocused = true
        }
    }

    private func addToCart() {
        guard !isLoading, !sentToPhone else { return }
        isLoading = true

        Task {
            // POST cart intent al backend — handoff a iPhone
            let url = URL(string: "\(backendUrl)/api/cart-intent")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
            request.httpBody = try? JSONSerialization.data(withJSONObject: [
                "userId": userId,
                "campaignId": campaignId,
                "productId": product.id,
            ])

            let success: Bool
            if let (_, response) = try? await URLSession.shared.data(for: request),
               let http = response as? HTTPURLResponse {
                success = (200...299).contains(http.statusCode)
            } else {
                // Demo: simular éxito si no hay endpoint
                success = true
            }

            await MainActor.run {
                isLoading = false
                sentToPhone = success
                if success {
                    NotificationCenter.default.post(name: .tvCartIntentSent, object: nil)
                }
            }
        }
    }
}
