import Foundation

/// Owns the TV session lifecycle against the Vio backend.
///
/// `/api/sdk/tv/broadcast/subscribe` created the row; this manager keeps it
/// alive via `POST /api/sdk/tv/session/heartbeat` every 60s and closes it with
/// `POST /api/sdk/tv/session/end` on `disconnect()`.
///
/// The host app never interacts with this directly — ``VioTVManager`` drives it.
internal final class VioTVSessionManager {
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: TimeInterval = 60

    /// Begins the 60s heartbeat loop. Cancels any previous loop first.
    func start(sessionId: Int) {
        heartbeatTask?.cancel()
        heartbeatTask = Task.detached { [interval = heartbeatInterval] in
            // Stagger the first heartbeat — subscribe already refreshed last_seen_at.
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            while !Task.isCancelled {
                await Self.sendHeartbeat(sessionId: sessionId)
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }

    /// Stops the heartbeat loop and POSTs `/session/end` for a clean close.
    /// Safe to call multiple times; second call is a no-op because the
    /// backend treats repeated ends as idempotent.
    func end(sessionId: Int) async {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        await Self.sendEnd(sessionId: sessionId)
    }

    // MARK: - HTTP helpers (nonisolated — the background heartbeat task calls them)

    private static func sendHeartbeat(sessionId: Int) async {
        await post(path: "/api/sdk/tv/session/heartbeat", sessionId: sessionId, context: "heartbeat")
    }

    private static func sendEnd(sessionId: Int) async {
        await post(path: "/api/sdk/tv/session/end", sessionId: sessionId, context: "end")
    }

    private static func post(path: String, sessionId: Int, context: String) async {
        let config = await MainActor.run { VioTVConfiguration.shared }
        let backend = await MainActor.run { VioTVConfiguration.shared.backendURL }
        let apiKey = await MainActor.run { VioTVConfiguration.shared.apiKey }
        _ = config
        guard let url = URL(string: "\(backend)\(path)"), !apiKey.isEmpty else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["sessionId": sessionId])
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                print("[VioTV] \(context) HTTP \(http.statusCode) — sessionId=\(sessionId)")
            }
        } catch {
            print("[VioTV] \(context) failed: \(error)")
        }
    }
}
