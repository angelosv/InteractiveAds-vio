// ⚠️ VIOBOT-OWNED — Do not modify this file manually or via Cursor.
import SwiftUI

// Custom ButtonStyle que bloquea el focus lift de tvOS
struct TVRawButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

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

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let blue = Color(red: 59/255, green: 130/255, blue: 246/255)
    private let bg   = Color(red: 18/255, green: 16/255, blue: 28/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── TOP ─────────────────────────────────
            HStack(alignment: .center, spacing: 14) {

                // Imagen + badge NEW
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("NEW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(8)
                }

                // Info
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(blue)
                            }
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

                        Text("TORSHOV SPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.5))
                            .kerning(1.1)
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // ── BOTÓN ────────────────────────────────
            Button(action: onAddToCart) {
                HStack(spacing: 8) {
                    Spacer()
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Image(systemName: "cart.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .background(focused ? blue : blue.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(TVRawButtonStyle())   // ← bloquea tvOS lift/white
            .focused($focused)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
            }
        }
        .frame(width: 400)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 32, x: 0, y: 12)
        .focusSection()
    }
}
