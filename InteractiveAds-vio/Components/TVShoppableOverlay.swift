import SwiftUI

/// Overlay con product card shoppable — estilo referencia Vileda.
/// Fondo #120019, texto blanco, etiquetas en noruego. Datos reales de Commerce API.
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

/// Product card — fondo #120019, texto blanco, borde sutil. Datos reales de Commerce API.
struct TVShoppableProductCard: View {
    let product: CommerceProduct
    let onAddToCart: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isAddToCartFocused: Bool

    private let cardBackground = Color(red: 18/255, green: 0/255, blue: 25/255)
    private let accentYellow = Color(red: 0.85, green: 0.7, blue: 0.2)

    private var originalPrice: Double? { product.price?.compareAtAmount }
    private var discountPercent: Int? {
        guard let orig = originalPrice, orig > 0,
              let current = product.price?.amount_incl_taxes ?? product.price?.amount,
              current < orig else { return nil }
        return Int(round((1 - current / orig) * 100))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Imagen producto — real desde Commerce API
            AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.3)))
                }
            }
            .frame(width: 100, height: 100)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 12) {
                // Nombre producto
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(accentYellow.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Text(product.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }

                // Precio actual + descuento + recomendado (solo si hay datos reales)
                HStack(alignment: .center, spacing: 8) {
                    Text(product.formattedPrice)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    if let discount = discountPercent {
                        Text("-\(discount)%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentYellow)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    if let orig = originalPrice {
                        Text("Anbefalt: \(formatPrice(orig))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Botón Add to cart — foco por defecto para mando Apple TV
                Button(action: onAddToCart) {
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isAddToCartFocused ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isAddToCartFocused ? Color.white : Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .focused($isAddToCartFocused)
                .onAppear {
                    DispatchQueue.main.async {
                        isAddToCartFocused = true
                    }
                }

                // Link detalles
                Button(action: onDismiss) {
                    Text("Detaljer og levering")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 380, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 4)
        .focusSection()
    }

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let num = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "kr \(num),-"
    }
}
