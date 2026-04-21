# CONTEXT.md — InteractiveAds-vio (modular SDK)

Source of truth for agents and maintainers. This file reflects the current modular architecture.

## What this repo is now

`InteractiveAds-vio` is no longer a single-target demo app. It is a modular Swift package plus a demo app:

- `VioTVCore`
- `VioTVCommerce`
- `VioTVUI`
- `VioTV` (public facade)
- `Demo/tv2demo-appletv` (integration sample)

Primary reference docs:

- `README.md`
- `docs/SDK_ARCHITECTURE.md`

## Package structure

- `Package.swift`: defines products/targets and target dependencies.
- `Sources/VioTVCore`: config/discovery/runtime/models.
- `Sources/VioTVCommerce`: commerce GraphQL lookup.
- `Sources/VioTVUI`: shoppable overlay UI.
- `Sources/VioTV`: public facade and orchestration.
- `Tests`: Core/Commerce unit tests.

## Runtime behavior summary

1. App configures SDK through `VioTV.configure(...)` or `VioTV.configureFromBundle(...)`.
2. App starts websocket flow with `VioTV.connect(...)`.
3. Core ingests backend events (`product` or `shoppable_ad`) and publishes `activeAd`.
4. UI observes `activeAd` and renders overlay.
5. CTA sends cart-intent via Core manager.
6. `VioTV.onCartIntent` callback is fired only on successful 2xx response.

## Configuration discovery

`VioTVConfigurationLoader` bundle search order:

1. explicit file name (if passed)
2. `VIO_CONFIG_TYPE=<name>` -> `vio-config-<name>.json` (if env var exists)
3. `vio-config.json`
4. `vio-config-automatic.json`
5. `vio-config-example.json`
6. `vio-config-dark-streaming.json`

Expected JSON keys:

- `apiKey`
- `commerceApiKey`
- `campaignId` (optional, used by `VioTV.connect()`)
- `userId` (optional)
- `environment` (`development` or `testing`)
- optional overrides:
  - `backendUrl`
  - `webSocketUrl`
  - `commerceUrl`
  - `devBackendURL`
  - `devWebSocketBaseURL`
  - `devCommerceURL`

Environment defaults:

- `development`:
  - backend: `https://api-local-angelo.vio.live`
  - websocket: `wss://api-local-angelo.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`
- `testing`:
  - backend: `https://api-dev.vio.live`
  - websocket: `wss://api-dev.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`

## Important contracts and guardrails

- Do not reintroduce networking into UI module.
- Do not import SwiftUI into Core or Commerce.
- Do not trigger cart success callbacks on failed network responses.
- Preserve campaign IDs from backend events to avoid invalid `/campaigns/0` requests.
- Keep generated files out of source control (`.build`, `.swiftpm`, `xcuserdata`, `*.xcuserstate`, `*.mp4`).

## Demo app responsibilities

The demo should stay thin:

- configure SDK from bundle
- connect/disconnect
- render `VioTVShoppableOverlay`

No business logic should live in demo views.

## Quick verification commands

```bash
swift build
swift test
```
