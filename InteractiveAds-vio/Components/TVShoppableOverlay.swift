// ⚠️ VIOBOT-OWNED — Do not modify this file manually or via Cursor.
import SwiftUI

struct TVShoppableOverlay: View {
    let product: CommerceProduct
    let onAddToCart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                TVShoppableProductCard(product: product, onAddToCart: onAddToCart, onDismiss: onDismiss)
                    .padding(.leading, 60)
                    .padding(.bottom, 80)
                Spacer()
            }
        }
    }
}

struct TVShoppableProductCard: View {
    let product: CommerceProduct
    let onAddToCart: () -> Void
    let onDismiss: () -> Void

    @FocusState private var focused: Bool
    @State private var confirmed = false

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let purple = Color(red: 0.404, green: 0.008, blue: 1.0)
    private let bg     = Color(red: 0.071, green: 0.063, blue: 0.110)

    private func handleTap() {
        print("🛒 [TVCard] handleTap llamado")
        guard !confirmed else { return }
        withAnimation(.spring(response: 0.3)) { confirmed = true }
        onAddToCart()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { onDismiss() }
        }
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .center, spacing: 16) {

                    ZStack(alignment: .topLeading) {
                        AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Rectangle().fill(Color.white.opacity(0.05))
                            }
                        }
                        .frame(width: 120, height: 120)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Text("NEW")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.863, green: 0.149, blue: 0.149))
                            .clipShape(Capsule())
                            .padding(8)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Circle().fill(purple)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                            Text("TORSHOV SPORT")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.65))
                                .kerning(0.8)
                        }

                        Text(product.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(product.formattedPrice)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)

                HStack(spacing: 10) {
                    Spacer()
                    if confirmed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Sendt til din mobil!")
                            .font(.system(size: 16, weight: .bold))
                    } else {
                        Text("Legg i handlekurv")
                            .font(.system(size: 16, weight: .bold))
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14))
                    }
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(confirmed ? Color(red: 0.133, green: 0.545, blue: 0.133) : (focused ? purple : purple.opacity(0.85)))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .animation(.spring(response: 0.3), value: confirmed)
            }
            .frame(width: 380)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.6), radius: 28, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .focused($focused)
        .scaleEffect(focused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: focused)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }
}
