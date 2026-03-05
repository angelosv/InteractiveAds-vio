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

    // Sponsor Torshov Sport
    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"

    // Design tokens
    private let cardW: CGFloat   = 440
    private let imgSize: CGFloat = 130
    private let blue = Color(red: 59/255, green: 130/255, blue: 246/255)
    private let bg   = Color(red: 15/255,  green: 12/255,  blue: 22/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Contenido superior ──────────────────
            HStack(alignment: .center, spacing: 16) {

                // Imagen + badge
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(width: imgSize, height: imgSize)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("NEW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(red: 220/255, green: 38/255, blue: 38/255))
                        .clipShape(Capsule())
                        .padding(8)
                }

                // Info
                VStack(alignment: .leading, spacing: 8) {

                    // Sponsor row
                    HStack(spacing: 7) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(blue)
                            }
                        }
                        .frame(width: 22, height: 22)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                        Text("TORSHOV SPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.5))
                            .kerning(1.2)
                    }

                    // Nombre
                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Precio
                    Text(product.formattedPrice)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(width: cardW - imgSize - 16 - 32 - 16, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 14)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // ── Botón full-width ────────────────────
            Button(action: onAddToCart) {
                HStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .focused($focused)
            .background(focused ? blue : blue.opacity(0.75))
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
                    .inset(by: 10)
                    .offset(y: -10)
            )
            .overlay(
                // Bottom rounded corners only
                RoundedRectangle(cornerRadius: 18)
                    .stroke(focused ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1.5)
                    .mask(
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 30)
                            Color.white
                        }
                    )
            )
            .scaleEffect(focused ? 1.015 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: focused)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
            }
        }
        .frame(width: cardW)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 32, x: 0, y: 12)
        .focusSection()
    }
}
