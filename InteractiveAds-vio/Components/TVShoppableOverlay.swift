// ⚠️ VIOBOT-OWNED — Do not modify this file manually or via Cursor.
import SwiftUI
import UIKit

// UIButton(type: .custom) = sin efecto blanco de tvOS
struct TVCustomButton: UIViewRepresentable {
    let title: String
    let icon: String
    let bgColor: UIColor
    let action: () -> Void
    @Binding var focused: Bool

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    func makeUIView(context: Context) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle("  \(title)", for: .normal)
        btn.setImage(UIImage(systemName: icon), for: .normal)
        btn.tintColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        btn.backgroundColor = bgColor
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .primaryActionTriggered)
        return btn
    }

    func updateUIView(_ btn: UIButton, context: Context) {
        btn.backgroundColor = focused ? bgColor : bgColor.withAlphaComponent(0.82)
    }

    class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tapped() { action() }
    }
}

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

    private let sponsorLogoUrl = "https://api-dev.vio.live/objects/uploads/e166816b-48e8-4e9f-98fa-53d164a2ab6f"
    private let blue    = Color(red: 0.231, green: 0.510, blue: 0.965)
    private let blueUI  = UIColor(red: 0.231, green: 0.510, blue: 0.965, alpha: 1)
    private let bg      = Color(red: 0.071, green: 0.063, blue: 0.110)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center, spacing: 14) {
                // Imagen
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: product.primaryImageUrl ?? "")) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle().fill(Color.white.opacity(0.05))
                        }
                    }
                    .frame(width: 130, height: 130)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("NEW")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9).padding(.vertical, 3)
                        .background(Color(red: 0.863, green: 0.149, blue: 0.149))
                        .clipShape(Capsule())
                        .padding(8)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        AsyncImage(url: URL(string: sponsorLogoUrl)) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else { Circle().fill(blue) }
                        }
                        .frame(width: 20, height: 20)
                        .clipShape(Circle())

                        Text("TORSHOV SPORT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.5))
                            .kerning(1.0)
                    }

                    Text(product.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(3)

                    Text(product.formattedPrice)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(.white)
                }
                .frame(width: 220, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Botón UIKit — sin halo blanco tvOS
            TVCustomButton(
                title: "Legg i handlekurv",
                icon: "cart.fill",
                bgColor: blueUI,
                action: onAddToCart,
                focused: $focused
            )
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .focused($focused)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: 400)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.7), radius: 32, x: 0, y: 12)
        .focusSection()
    }
}
