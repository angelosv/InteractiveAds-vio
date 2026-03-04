import SwiftUI

struct TVShoppableOverlay: View {
    let product: TVProduct
    let sponsor: TVSponsor
    let onDismiss: () -> Void

    @State private var appeared = false
    @FocusState private var isButtonFocused: Bool

    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                // Sponsor badge
                HStack {
                    Spacer()
                    AsyncImage(url: URL(string: sponsor.logoUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            Text(sponsor.name).font(.caption).foregroundColor(.white)
                        }
                    }
                    .frame(height: 28)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding([.top, .trailing], 16)

                // Product image
                AsyncImage(url: URL(string: product.imageUrl)) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.08))
                            .overlay(Image(systemName: "tv").font(.largeTitle).foregroundColor(.white.opacity(0.4)))
                    }
                }
                .frame(width: 320, height: 200)
                .clipped()

                // Product info
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    Text(product.formattedPrice)
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.yellow)

                    // CTA button
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Se mer på Elkjøp")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            isButtonFocused
                            ? Color.yellow
                            : Color.white.opacity(0.2)
                        )
                        .foregroundColor(isButtonFocused ? .black : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .scaleEffect(isButtonFocused ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3), value: isButtonFocused)
                    }
                    .focused($isButtonFocused)
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.07, green: 0.07, blue: 0.12).opacity(0.95))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: -5, y: 0)
            )
            .offset(x: appeared ? 0 : 400)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)
            .padding(.trailing, 60)
        }
        .onAppear {
            appeared = true
            isButtonFocused = true
        }
        // Auto-dismiss after 15 seconds
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                withAnimation { onDismiss() }
            }
        }
    }
}
