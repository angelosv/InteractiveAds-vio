import SwiftUI
import VioTV

/// Landing view that lets you pick between a broadcast the backend knows about
/// (subscribe returns `{ subscribed: true, ... }`) and one it doesn't (soft-miss
/// with `{ subscribed: false, reason: "broadcast_not_registered_for_client_app" }`).
/// Both choices reuse the same `TVPlayerView` so the video + overlay behaviour
/// is identical — only the SDK outcome differs, which is the whole point.
struct BroadcastPickerView: View {
    private let validBroadcastId = "barcelona-psg-2026-03-03"
    private let unknownBroadcastId = "broadcast-no-existe-demo"

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.05, blue: 0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Text("Vio TV Demo")
                    .font(.largeTitle).bold()
                    .foregroundStyle(.white)
                Text("Elige un broadcast para ver cómo responde el SDK")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 40) {
                    NavigationLink(destination: TVPlayerView(broadcastId: validBroadcastId)) {
                        BroadcastCard(
                            title: "Broadcast registrado",
                            subtitle: validBroadcastId,
                            hint: "Subscribe OK → WS abre → overlay funciona",
                            tint: .green
                        )
                    }
                    .buttonStyle(.card)

                    NavigationLink(destination: TVPlayerView(broadcastId: unknownBroadcastId)) {
                        BroadcastCard(
                            title: "Broadcast desconocido",
                            subtitle: unknownBroadcastId,
                            hint: "Soft-miss → SDK idle, overlay nunca aparece",
                            tint: .orange
                        )
                    }
                    .buttonStyle(.card)
                }
            }
            .padding(80)
        }
    }
}

private struct BroadcastCard: View {
    let title: String
    let subtitle: String
    let hint: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title2).bold().foregroundStyle(.white)
            Text(subtitle)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
            Divider().background(.white.opacity(0.3))
            Text(hint).font(.callout).foregroundStyle(.white.opacity(0.75))
        }
        .padding(32)
        .frame(width: 520, height: 280, alignment: .topLeading)
        .background(tint.opacity(0.25))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(tint, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
