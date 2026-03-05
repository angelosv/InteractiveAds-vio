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

struct TVRawButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct TVShoppableProductCard: View {
    let product: CommerceProduct
    let onAddToCart: () -> Void
    let onDismiss: () -> Void

    @FocusState private var focused: Bool

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let blue = Color(red: 0.231, green: 0.510, blue: 0.965)
    private let bg   = Color(red: 0.071, green: 0.063, blue: 0.110)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Imagen + info ──
            HStack(alignment: .center, spacing: 16) {

                // Imagen producto + badge NEW
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

                // Texto
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(blue)
                            }
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())

                        Text("TORSHOV SPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.5))
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

            // ── Botón full width ──
            Button(action: onAddToCart) {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "cart.fill")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(TVRawButtonStyle())
            .focused($focused)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
            }
        }
        .frame(width: 380)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.6), radius: 28, x: 0, y: 8)
        .focusSection()
    }
}
