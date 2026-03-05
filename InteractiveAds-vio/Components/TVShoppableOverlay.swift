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
    private let sponsorColor = Color(red: 0.23, green: 0.51, blue: 0.96)

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            // IZQUIERDA — Avatar sponsor
            AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Circle().fill(sponsorColor)
                        .overlay(Text("T").font(.caption).bold().foregroundColor(.white))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
            .padding(.leading, 20)

            // CENTRO — Imagen producto
            AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.3)))
                }
            }
            .frame(width: 120, height: 120)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)

            // DERECHA — Info
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(product.formattedPrice)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Button(action: onAddToCart) {
                    Text("Legg i handlekurv")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isAddToCartFocused ? .black : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(isAddToCartFocused ? Color.white : sponsorColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaleEffect(isAddToCartFocused ? 1.04 : 1.0)
                        .animation(.spring(response: 0.2), value: isAddToCartFocused)
                }
                .buttonStyle(.plain)
                .focused($isAddToCartFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAddToCartFocused = true
                    }
                }
            }
            .frame(width: 240)
            .padding(.trailing, 24)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.05, green: 0.0, blue: 0.1).opacity(0.82))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.6), radius: 24, x: 0, y: 8)
        .focusSection()
    }
}
