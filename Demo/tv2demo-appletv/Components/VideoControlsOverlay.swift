import SwiftUI

/// Controles de video estilo referencia: morado claro, blanco, fondo oscuro.
/// Visibles al inicio, se ocultan tras inactividad, reaparecen al recibir foco.
struct VideoControlsOverlay: View {
    @ObservedObject var viewModel: VideoPlayerViewModel

    @State private var controlsVisible = true
    @State private var hideWorkItem: DispatchWorkItem?
    @FocusState private var isOverlayFocused: Bool

    private let accentPurple = Color(red: 0.55, green: 0.36, blue: 0.96)
    private let hideDelay: TimeInterval = 3

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            controlsContent
                .opacity(controlsVisible ? 1 : 0)
                .allowsHitTesting(controlsVisible)
                .animation(.easeInOut(duration: 0.3), value: controlsVisible)
        }
        .onChange(of: isOverlayFocused) { focused in
            if focused {
                showControls()
            } else {
                scheduleHide()
            }
        }
        .onAppear {
            controlsVisible = true
            scheduleHide()
        }
        .onDisappear {
            cancelHide()
        }
    }

    private var controlsContent: some View {
        VStack(spacing: 12) {
            // Progress bar
            progressBar

            // Controls row
            HStack(spacing: 20) {
                // Play/Pause
                Button(action: {
                    showControls()
                    viewModel.togglePlayPause()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(accentPurple)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                // Rewind (decorativo)
                Image(systemName: "gobackward.10")
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                // Forward (decorativo)
                Image(systemName: "goforward.10")
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                // Volume (decorativo)
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                Spacer()

                // Time
                Text(timeString)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                // Settings (decorativo)
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)

                // PiP (decorativo)
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .padding(.top, 12)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .focusable()
        .focused($isOverlayFocused)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = viewModel.duration > 0 ? min(1, max(0, viewModel.currentTime / viewModel.duration)) : 0
            let filledWidth = width * progress
            let scrubberX = min(width - 6, max(0, filledWidth - 6))

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)

                // Filled progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentPurple)
                    .frame(width: filledWidth, height: 4)

                // Scrubber
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: scrubberX)
            }
        }
        .frame(height: 12)
        .padding(.horizontal, 24)
    }

    private var timeString: String {
        let current = formatTime(viewModel.currentTime)
        let total = formatTime(viewModel.duration)
        return "\(current) / \(total)"
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func showControls() {
        cancelHide()
        controlsVisible = true
        scheduleHide()
    }

    private func scheduleHide() {
        cancelHide()
        let work = DispatchWorkItem { [self] in
            controlsVisible = false
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + hideDelay, execute: work)
    }

    private func cancelHide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil
    }
}
