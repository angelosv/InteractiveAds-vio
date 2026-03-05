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

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let blue = Color(red: 59/255, green: 130/255, blue: 246/255)
    private let bg   = Color(red: 18/255, green: 16/255, blue: 28/255)
    private let cardW: CGFloat = 420

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── TOP: imagen + info ─────────────────
            HStack(alignment: .top, spacing: 14) {

                // Imagen
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(width: 130, height: 130)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("NEW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(8)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else { Circle().fill(blue) }
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

                        Text("TORSHOV SPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .kerning(1.0)
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
                .frame(width: cardW - 130 - 14 - 16 - 16, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Separador
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // ── BOTÓN — ZStack focusable, sin Button → sin halo tvOS ──
            ZStack {
                (focused ? blue : blue.opacity(0.8))
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15))
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .bold))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 15)
            }
            .frame(maxWidth: .infinity)
            .focusable(true)
            .focused($focused)
            .onTapGesture { onAddToCart() }
            .scaleEffect(focused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: focused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
            }
        }
        .frame(width: cardW)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))  // clip DESPUÉS del botón
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 32, x: 0, y: 12)
        .focusSection()
    }
}
