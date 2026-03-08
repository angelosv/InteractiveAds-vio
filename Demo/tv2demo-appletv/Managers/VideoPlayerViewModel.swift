import Foundation
import AVFoundation
import Combine

class VideoPlayerViewModel: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = true

    private(set) var player: AVPlayer?
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?

    func configure(with player: AVPlayer) {
        self.player = player
        isPlaying = player.timeControlStatus == .playing

        // Observe duration when item loads
        if let item = player.currentItem {
            observeDuration(item: item)
        }

        // Periodic time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Observe play/pause status
        statusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                self?.isPlaying = player.timeControlStatus == .playing
            }
        }
    }

    private func observeDuration(item: AVPlayerItem) {
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            var error: NSError?
            let status = item.asset.statusOfValue(forKey: "duration", error: &error)
            guard status == .loaded else { return }
            DispatchQueue.main.async {
                let dur = item.duration
                let secs = dur.seconds
                self?.duration = secs.isFinite && secs > 0 ? secs : 0
            }
        }
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: time)
    }

    func cleanup() {
        if let token = timeObserverToken, let p = player {
            p.removeTimeObserver(token)
        }
        timeObserverToken = nil
        statusObserver?.invalidate()
        statusObserver = nil
    }

    deinit {
        cleanup()
    }
}
