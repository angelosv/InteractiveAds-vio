# InteractiveAds-vio

Modular tvOS shoppable ads SDK + demo app.

This repository now follows a modular SDK structure similar to `VioSwiftSDK`:

- `VioTVCore`: configuration, runtime, WebSocket ingestion, shared domain models, cart-intent orchestration.
- `VioTVCommerce`: Commerce GraphQL product lookup.
- `VioTVUI`: SwiftUI shoppable overlay and card components.
- `VioTV`: public facade that composes all modules.

The demo app under `Demo/tv2demo-appletv` only initializes the SDK, connects to a broadcast, and renders the SDK overlay.

## Repository layout

- `Package.swift`: SPM products and target dependencies.
- `Sources/VioTVCore`: core runtime and config loader.
- `Sources/VioTVCommerce`: GraphQL commerce service.
- `Sources/VioTVUI`: overlay UI.
- `Sources/VioTV`: public API facade.
- `Demo/tv2demo-appletv`: sample app that consumes `VioTV`.
- `Tests`: package-level unit tests for Core and Commerce.

## Public SDK usage

Example integration in a broadcaster app:

```swift
import SwiftUI
import VioTV

@main
struct MyApp: App {
    init() {
        try? VioTV.configureFromBundle(userIdOverride: "demo_user_001")
        VioTV.onCartIntent = { productId in
            print("cart intent sent for: \(productId)")
        }
    }

    var body: some Scene {
        WindowGroup { PlayerScreen() }
    }
}

struct PlayerScreen: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VioTVShoppableOverlay()
        }
        .onAppear { VioTV.connect() }
        .onDisappear { VioTV.disconnect() }
    }
}
```

You can also connect explicitly:

```swift
VioTV.connect(broadcastId: "36")
```

## Configuration and discovery

`VioTV.configureFromBundle()` uses `VioTVConfigurationLoader` to discover a JSON config in this order:

1. `vio-config.json`
2. `vio-config-automatic.json`
3. `vio-config-example.json`

Supported config fields:

```json
{
  "apiKey": "tv2_api_key_xxx",
  "commerceApiKey": "commerce_api_key_xxx",
  "campaignId": 36,
  "userId": "optional_user",
  "environment": "development",
  "backendUrl": "https://api-local-angelo.vio.live/",
  "webSocketUrl": "wss://api-local-angelo.vio.live/ws",
  "commerceUrl": "https://api-local-angelo.vio.live/graphql",
  "devBackendURL": "http://localhost:4000",
  "devWebSocketBaseURL": "ws://localhost:4000/ws",
  "devCommerceURL": "http://localhost:4000/graphql"
}
```

`campaignId` is used by `VioTV.connect()` when no explicit broadcast id is provided.

Discovery also supports `VIO_CONFIG_TYPE=<name>` to load `vio-config-<name>.json`.

Supported environments:

- `development`
- `testing`

Current defaults:

- `development`
  - backend: `https://api-local-angelo.vio.live`
  - websocket: `wss://api-local-angelo.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`
- `testing`
  - backend: `https://api-dev.vio.live`
  - websocket: `wss://api-dev.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`

## Runtime flow

1. App configures SDK (`configure(...)` or `configureFromBundle(...)`).
2. App connects with `VioTV.connect(...)`.
3. `VioTVCore` listens on WebSocket and maps backend events into `ShoppableAdEvent`.
4. `VioTVUI` observes `VioTVManager.shared.activeAd` and renders the overlay.
5. Tap on CTA sends cart-intent to `/api/campaigns/{campaignId}/cart-intent`.
6. `VioTV.onCartIntent` callback is triggered only on successful HTTP 2xx response.

If incoming product payload is incomplete (missing image/title/price), `VioTV` facade attempts enrichment through `VioTVCommerceService`.

## Testing

Run package tests:

```bash
swift test
```

Current suite covers:

- core product/event decoding behavior
- campaign id propagation from backend event mapping
- configuration persistence and environment URLs
- commerce GraphQL response decoding

## Development notes

- Build artifacts and local user files are intentionally ignored (`.build`, `.swiftpm`, `xcuserdata`, `*.xcuserstate`, `*.mp4`).
- Avoid adding generated files back to git.
- Keep module boundaries strict:
  - Core must not import UI.
  - Commerce should depend only on Core.
  - UI should depend only on Core domain/runtime.
