// ⚠️ VIOBOT-OWNED — Do not modify this file manually or via Cursor.
// All changes go through Viobot (OpenClaw) only.
import SwiftUI

struct TVShoppableOverlay: View {
    let product: CommerceProduct
    let onAddToCart: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack {
                TVShoppableProductCard(
                    product: product,
                    onAddToCart: onAddToCart,
                    onDismiss: onDismiss
                )
                .padding(.leading, 60)
                .padding(.bottom, 100)
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
    private let sponsorName = "TORSHOV SPORT"
    private let accentBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let cardBg = Color(red: 0.08, green: 0.07, blue: 0.12)

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // — Imagen producto —
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.06))
                    }
                }
                .frame(width: 130, height: 130)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("NEW")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(10)
            }
            .padding(.leading, 16)
            .padding(.vertical, 16)

            // — Info —
            VStack(alignment: .leading, spacing: 8) {

                // Sponsor
                HStack(spacing: 6) {
                    AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(accentBlue)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())

                    Text(sponsorName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(1.0)
                }

                // Nombre
                Text(product.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Precio
                Text(product.formattedPrice)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)

                // — Botón full width —
                Button(action: onAddToCart) {
                    HStack(spacing: 8) {
                        Spacer()
                        Text("Legg i handlekurv")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "cart.fill")
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(focused ? accentBlue : accentBlue.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(focused ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                    .scaleEffect(focused ? 1.02 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: focused)
                }
                .buttonStyle(.plain)
                .focused($focused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        focused = true
                    }
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .frame(width: 460)
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.65), radius: 28, x: 0, y: 10)
        .focusSection()
    }
}
