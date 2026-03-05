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

    @FocusState private var isAddToCartFocused: Bool

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let sponsorName = "Torshov Sport"
    private let cardBg = Color(red: 0.09, green: 0.08, blue: 0.13)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // TOP — imagen + info
            HStack(alignment: .top, spacing: 0) {

                // Imagen producto con badge NEW
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.06))
                        }
                    }
                    .frame(width: 200, height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Badge NEW
                    Text("NEW")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .padding(12)
                }

                // Info derecha
                VStack(alignment: .leading, spacing: 10) {

                    // Sponsor: avatar + nombre
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Circle().fill(Color.blue)
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                        Text(sponsorName.uppercased())
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .kerning(1)
                    }

                    // Nombre producto
                    Text(product.name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    // Precio tachado (compareAt) si existe
                    if let compareAt = product.price?.compareAtAmount, compareAt > 0 {
                        Text(formatPrice(compareAt))
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.45))
                            .strikethrough(true, color: .white.opacity(0.45))
                    }

                    // Precio final
                    Text(product.formattedPrice)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 20)
                .padding(.trailing, 24)
                .padding(.top, 16)
                .frame(width: 280)
            }
            .padding(.top, 20)
            .padding(.leading, 20)

            // BOTTOM — botón full width
            Button(action: onAddToCart) {
                HStack {
                    Spacer()
                    Text("Legg i handlekurv →")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isAddToCartFocused ? .black : .black)
                    Spacer()
                }
                .padding(.vertical, 18)
                .background(isAddToCartFocused ? Color.white : Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .scaleEffect(isAddToCartFocused ? 1.02 : 1.0)
                .animation(.spring(response: 0.2), value: isAddToCartFocused)
            }
            .buttonStyle(.plain)
            .focused($isAddToCartFocused)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAddToCartFocused = true
                }
            }
        }
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 10)
        .focusSection()
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 0
        return "kr \(formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"),-"
    }
}
