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
        HStack(alignment: .center, spacing: 0) {

            // Imagen producto
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.06))
                    }
                }
                .frame(width: 160, height: 160)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Text("NEW")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(10)
            }
            .padding(.leading, 20)

            // Info
            VStack(alignment: .leading, spacing: 10) {

                // Sponsor
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(Color.blue)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())

                    Text(sponsorName.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                        .kerning(0.8)
                }

                // Nombre
                Text(product.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Precio
                Text(product.formattedPrice)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                // Botón
                Button(action: onAddToCart) {
                    HStack {
                        Spacer()
                        Text("Legg i handlekurv →")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(isAddToCartFocused ? Color.white : Color.white.opacity(0.88))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAddToCartFocused ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(isAddToCartFocused ? 1.03 : 1.0)
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
            .padding(.leading, 20)
            .padding(.trailing, 24)
            .frame(width: 280)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 10)
        .focusSection()
    }
}
