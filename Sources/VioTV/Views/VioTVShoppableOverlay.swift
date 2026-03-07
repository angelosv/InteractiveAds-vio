import SwiftUI

/// Shoppable overlay that displays a product card from a ShoppableAdEvent.
/// Visual layout is identical to the original TVShoppableOverlay.
public struct VioTVShoppableOverlay: View {
    let event: ShoppableAdEvent
    let dismissAfter: TimeInterval
    var onDismiss: (() -> Void)?

    @State private var dismissed = false
    @State private var dismissWorkItem: DispatchWorkItem?

    public init(
        event: ShoppableAdEvent,
        dismissAfter: TimeInterval = 15,
        onDismiss: (() -> Void)? = nil
    ) {
        self.event = event
        self.dismissAfter = dismissAfter
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if !dismissed {
            VStack {
                Spacer()
                HStack {
                    VioTVShoppableProductCard(
                        event: event,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.35)) {
                                dismissed = true
                            }
                            onDismiss?()
                        }
                    )
                    .padding(.leading, 60)
                    .padding(.bottom, 80)
                    Spacer()
                }
            }
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .bottom)),
                removal: .opacity.combined(with: .move(edge: .bottom))
            ))
            .onAppear {
                let work = DispatchWorkItem {
                    withAnimation(.easeIn(duration: 0.35)) {
                        dismissed = true
                    }
                    onDismiss?()
                }
                dismissWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter, execute: work)
            }
            .onDisappear {
                dismissWorkItem?.cancel()
            }
        }
    }
}

// MARK: - Product Card (visual identical to TVShoppableProductCard)

struct VioTVShoppableProductCard: View {
    let event: ShoppableAdEvent
    let onDismiss: () -> Void

    @FocusState private var focused: Bool
    @State private var confirmed = false

    private let purple = Color(red: 0.404, green: 0.008, blue: 1.0)
    private let bg     = Color(red: 0.071, green: 0.063, blue: 0.110)

    private var product: ShoppableProduct { event.product }
    private var sponsor: ShoppableSponsor? { event.sponsor }

    private var sponsorColor: Color {
        guard let hex = sponsor?.primaryColor else { return purple }
        return Color(hex: hex) ?? purple
    }

    private func handleTap() {
        print("[VioTV] Card tap — sending cart intent")
        guard !confirmed else { return }
        withAnimation(.spring(response: 0.3)) { confirmed = true }

        Task { @MainActor in
            VioTVManager.shared.sendCartIntent(productId: product.id, campaignId: event.campaignId ?? 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { onDismiss() }
        }
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 0) {

                HStack(alignment: .center, spacing: 14) {

                    // Product image — 150x150
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

                    // Info column — aligned top-to-bottom with image
                    VStack(alignment: .leading, spacing: 0) {
                        // TOP: Sponsor
                        HStack(spacing: 6) {
                            if let logoUrl = sponsor?.logoUrl {
                                AsyncImage(url: URL(string: logoUrl)) { phase in
                                    if case .success(let img) = phase {
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        Circle().fill(purple)
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            } else {
                                Circle().fill(purple)
                                    .frame(width: 24, height: 24)
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }

                            Text((sponsor?.name ?? "").uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.white.opacity(0.65))
                                .kerning(0.8)
                        }

                        // Title
                        Text(product.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)

                        Spacer(minLength: 8)

                        // BOTTOM: Badge + price
                        VStack(alignment: .leading, spacing: 4) {
                            if let badge = event.discountBadge {
                                Text(badge)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(purple)
                                    .clipShape(Capsule())
                            }

                            Text(product.formattedPrice)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 150)
                }
                .padding(16)

                // Button
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

// MARK: - NoHaloButtonStyle (tvOS focus halo removal)

struct NoHaloButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .focusEffectDisabled()
    }
}

// MARK: - Color hex initializer

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let intVal = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((intVal >> 16) & 0xFF) / 255.0
        let g = Double((intVal >> 8) & 0xFF) / 255.0
        let b = Double(intVal & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
