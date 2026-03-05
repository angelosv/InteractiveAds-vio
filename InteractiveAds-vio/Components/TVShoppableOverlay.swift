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

    @FocusState private var isButtonFocused: Bool
    @State private var showSuccess = false

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let sponsorName = "Torshov Sport"
    private let cardBg = Color(red: 0.09, green: 0.08, blue: 0.13).opacity(0.75)
    private let accentColor = Color(red: 67/255, green: 2/255, blue: 1)

    private let imageSize: CGFloat = 220

    var body: some View {
        HStack(alignment: .top, spacing: 20) {

            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.06))
                    }
                }
                .frame(width: imageSize, height: imageSize)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("NEW")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(10)
            }
            .frame(width: imageSize, height: imageSize)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(Color.blue)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())

                    Text(sponsorName.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                        .kerning(0.8)
                }

                Text(product.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                Text(product.formattedPrice)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 2)

                Spacer(minLength: 0)

                // Botón custom sin .buttonStyle — evita el foco blanco nativo de tvOS
                ZStack {
                    HStack(spacing: 8) {
                        Text("Legg i handlekurv")
                        Image(systemName: "cart.fill")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showSuccess ? 0 : 1)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                        Text("Lagt til!")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .opacity(showSuccess ? 1 : 0)
                    .scaleEffect(showSuccess ? 1 : 0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(showSuccess ? Color(red: 0.15, green: 0.7, blue: 0.35) : accentColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isButtonFocused ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                )
                .focusable(true)
                .focused($isButtonFocused)
                .onLongPressGesture(minimumDuration: 0.01) {
                    handleTap()
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSuccess)
                .animation(.easeInOut(duration: 0.15), value: isButtonFocused)
            }
            .frame(width: 250, height: imageSize)
        }
        .padding(28)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22)
                    .fill(cardBg)
            }
        )
        .shadow(color: .black.opacity(0.7), radius: 30, x: 0, y: 10)
        .focusSection()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isButtonFocused = true
            }
        }
    }

    private func handleTap() {
        guard !showSuccess else { return }
        onAddToCart()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.25)) {
                showSuccess = false
            }
        }
    }
}
