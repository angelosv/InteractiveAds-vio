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

                HStack(alignment: .center, spacing: 14) {

                    // Imagen — más grande
                    AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(width: 150, height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Info
                    VStack(alignment: .leading, spacing: 5) {
                        // Sponsor
                        HStack(spacing: 6) {
                            AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Circle().fill(purple)
                                }
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))

                            Text("TORSHOV SPORT")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.65))
                                .kerning(0.8)
                        }

                        // Título más pequeño
                        Text(product.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        // Precio + badge -20%
                        HStack(alignment: .center, spacing: 8) {
                            Text(product.formattedPrice)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)

                            Text("-20%")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(purple)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(purple.opacity(0.20))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(16)

                // Botón
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
            .frame(width: 400)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.6), radius: 28, x: 0, y: 8)
        }
        .buttonStyle(NoHaloButtonStyle())
        .focused($focused)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(focused ? Color.white.opacity(0.35) : Color.clear, lineWidth: 2)
        )
        .scaleEffect(focused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: focused)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }
}

struct NoHaloButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusEffectDisabled()
    }
}
