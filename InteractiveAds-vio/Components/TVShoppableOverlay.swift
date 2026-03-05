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
    private let sponsorName = "TORSHOV SPORT"
    private let accentBlue = Color(red: 0.23, green: 0.51, blue: 0.96)
    private let cardBg = Color(red: 0.08, green: 0.07, blue: 0.12)
    private let accentColor = Color(red: 67/255, green: 2/255, blue: 1)

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.06))
                    }
                }
                .frame(width: 180, height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Text("NEW")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .padding(12)
            }
            .padding(.leading, 20)
            .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 12) {

                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Circle().fill(accentBlue)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())

                    Text(sponsorName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .kerning(1.2)
                }

                Text(product.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                Text(product.formattedPrice)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 2)

                Spacer()

                ZStack {
                    HStack(spacing: 10) {
                        Text("Legg i handlekurv")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "cart.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                    .opacity(showSuccess ? 0 : 1)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                        Text("Lagt til!")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .opacity(showSuccess ? 1 : 0)
                    .scaleEffect(showSuccess ? 1 : 0.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(showSuccess ? Color(red: 0.15, green: 0.7, blue: 0.35) : accentColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
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
            .padding(.leading, 20)
            .padding(.trailing, 24)
            .padding(.top, 20)
            .padding(.bottom, 20)
            .frame(width: 300)
        }
        .background(cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.65), radius: 28, x: 0, y: 10)
        .focusSection()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
