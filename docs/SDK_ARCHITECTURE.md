# SDK Architecture Guide

This document explains how the consolidated SDK is structured, how data flows at runtime, and where to add new behavior safely.

**Backend contract**: this SDK pairs with the backend in `socket-server` (Vio backend monorepo). See `socket-server/docs/multi-sponsor-architecture.md` §7.4 for the matching multi-sponsor design and the endpoint specs.

## Design goals

- Mirror the modular style of `VioSwiftSDK`.
- Keep a thin public facade (`VioTV`) over focused modules.
- Ensure demo app stays minimal and does not own business logic.
- Make event ingestion and UI rendering evolvable without tight coupling.

## Modules and responsibilities

## `VioTVCore`

Path: `Sources/VioTVCore`

Responsibilities:

- Configuration primitives and environment URLs (`VioTVConfiguration`).
- Bundle config discovery (`VioTVConfigurationLoader`).
- WebSocket connection and event decoding/mapping (`VioTVWebSocketManager`).
- Shared domain models (`ShoppableAdEvent`, `ShoppableProduct`, etc.).
- Runtime state and cart-intent send (`VioTVManager`).

Core is the source of truth for active ad state (`activeAd`) and should remain UI-agnostic.

## `VioTVCommerce`

Path: `Sources/VioTVCommerce`

Responsibilities:

- Fetch products from Commerce GraphQL (`VioTVCommerceService`).
- Map GraphQL DTOs into Core domain models.

Rules:

- Depends on `VioTVCore`.
- Must not depend on UI.

## `VioTVUI`

Path: `Sources/VioTVUI`

Responsibilities:

- Render `VioTVShoppableOverlay` and product card.
- Observe `VioTVManager.shared.activeAd`.
- Trigger cart-intent through `VioTVManager`.

Rules:

- Depends on `VioTVCore`.
- Contains view styling and interaction behavior only.

## `VioTV` (Facade)

Path: `Sources/VioTV/VioTV.swift`

Responsibilities:

- Public entry point (`configure`, `configureFromBundle`, `connect`, `disconnect`).
- Bridge callback (`onCartIntent`).
- Optional enrichment from Commerce when WS payload is incomplete.
- Re-export Core/UI symbols for integrators.

Rules:

- Should stay thin and orchestration-focused.
- Business logic should live in module-specific targets.

## Runtime sequence (v2 — multi-sponsor subscribe flow)

1. App calls `VioTV.configureFromBundle(userIdOverride:)` once at launch.
   Local config now carries **only** `apiKey` + `userId` (optional) + environment.
2. App calls `VioTV.connect(broadcastId:)` with the partner's internal broadcast id.
3. SDK fires one request → `POST /api/sdk/tv/broadcast/subscribe` (see §Endpoints).
   - `subscribed: true` → SDK caches `primarySponsor` + `secondarySponsors` + `sessionId`
     in `VioTVConfiguration`, opens the WebSocket with the returned `wsUrl`, sends
     `{ "type": "identify", "userId": externalUserId }`, and starts a 60s heartbeat.
   - `subscribed: false` → SDK stays idle. Optional `VioTV.onSubscriptionFailed(reason)`.
4. WS messages accepted:
   - `type: "shoppable_ad"` — decoded as `ShoppableAdEvent` (includes `activationId` +
     `sponsorId` in v2).
   - `type: "product"` (legacy) — mapped to `ShoppableAdEvent` for backwards compat.
5. Core publishes `activeAd`.
6. Facade auto-enriches when product payload is incomplete — now it **routes** to
   the correct sponsor's Commerce GraphQL key via
   `VioTVConfiguration.shared.commerce(forSponsorId: event.sponsorId)`.
7. UI overlay renders when `activeAd != nil`.
8. On remote OK / tap, UI calls `VioTVManager.sendCartIntent(...)` which POSTs to
   **`/api/sdk/tv/cart-intent`** (not the legacy mobile endpoint) with
   `activationId` + `sponsorId` drawn from `activeAd`. Backend persists a
   `cart_intents` row with `source_activation_id = activationId` **and** forwards
   the envelope to the user's mobile device via the same delivery tree as the
   mobile cart-intent (local WS → Redis cluster → partner webhook → APNs).
   The partner companion SDK (`VioSwiftSDK`) consumes that envelope and opens
   its own product-detail overlay — see `VioSwiftSDK/Documentation/CART_INTENT_FLOW.md`
   for the full receive-side contract (dedup, per-sponsor Commerce routing).
9. `VioTV.disconnect()` closes the WS, stops the heartbeat, and POSTs
   `/api/sdk/tv/session/end` to mark the `tv_sessions` row closed.

## Endpoints the SDK consumes

All endpoints authenticate with `X-API-Key: <client_app.apiKey>`.

- **`POST /api/sdk/tv/broadcast/subscribe`** — combined bootstrap. Request body:
  `{ broadcastId, externalUserId, platform, tvDeviceId? }`. Response either
  `{ subscribed: true, campaignId, sessionId, endUserId, wsUrl, primarySponsor, secondarySponsors, capabilities }`
  or `{ subscribed: false, reason }` where reason is one of
  `broadcast_not_registered_for_client_app`, `campaign_has_no_primary_sponsor`,
  `tv_not_enabled_for_this_platform`.
- **`POST /api/sdk/tv/session/heartbeat`** — body `{ sessionId }`. Called every 60s.
- **`POST /api/sdk/tv/session/end`** — body `{ sessionId }`. Called on `disconnect()`.
- **`POST /api/sdk/tv/cart-intent`** — body
  `{ externalUserId, productId, campaignId, activationId?, sponsorId?, platform? }`.
  Backend persists and forwards.
- **Commerce GraphQL** (direct, not through Vio) — the SDK calls the endpoint returned
  in the subscribe response (`endpoints.commerceGraphQL` equivalent, stored as
  `VioTVConfiguration.shared.commerceURL`). Authorisation header is the sponsor's
  `commerce.apiKey` resolved via `VioTVConfiguration.shared.commerce(forSponsorId:)`.

## Supported backend event shapes

## Native shoppable event

```json
{
  "type": "shoppable_ad",
  "broadcastId": "barcelona-psg-2026-03-03",
  "campaignId": 36,
  "sponsorId": 3,
  "activationId": 10,
  "product": {
    "id": "408895",
    "title": "Samsung 85 Neo QLED 4K TV",
    "images": [{ "url": "https://...", "order": 0 }],
    "price": { "amount": 17990, "amount_incl_taxes": 17990, "currency_code": "NOK" }
  },
  "sponsor": {
    "id": 3,
    "name": "Elkjøp",
    "avatarUrl": "https://.../avatar.jpeg",
    "logoUrl":   "https://.../logo.png",
    "primaryColor": "#f7b23b"
  }
}
```

**Sponsor shape** — both `avatarUrl` (square brand mark, rendered inside the overlay /
product card) and `logoUrl` (wide horizontal logo, for sponsor intros) ship. The backend
rejects shoppable_ad dispatches for sponsors without an avatar (`422
SPONSOR_MISSING_AVATAR`), so `avatarUrl` is effectively non-null at render time. The
overlay still falls back to `logoUrl` defensively for legacy events pre-dating this
guarantee.

## Backend product event (mapped internally)

```json
{
  "type": "product",
  "campaignId": 36,
  "data": {
    "id": "evt_1",
    "productId": "408895",
    "name": "Samsung 85 Neo QLED 4K TV",
    "price": "17990",
    "currency": "NOK",
    "imageUrl": "https://..."
  }
}
```

## Configuration discovery details

`VioTVConfigurationLoader.loadConfiguration(fileName:bundle:)` search order:

1. Explicit filename if provided.
2. `VIO_CONFIG_TYPE=<name>` -> `vio-config-<name>.json` (if env var exists).
3. `vio-config`
4. `vio-config-automatic`
5. `vio-config-example`
6. `vio-config-dark-streaming`

Expected keys:

- `apiKey` (required)
- `broadcastId` (**preferred**) — partner-internal broadcast id (e.g. `"barcelona-psg-2026-03-03"`).
  Stored as `VioTVConfiguration.shared.defaultBroadcastId`. When set, bare `VioTV.connect()`
  uses it as the `broadcastId` argument to `POST /api/sdk/tv/broadcast/subscribe`. The key
  name matches the backend's `broadcasts.broadcast_id` column — was previously aliased as
  `contentId`, renamed for consistency with `socket-server` and the mobile SDK.
- `commerceApiKey` (**deprecated / dev-only** — production commerce keys come per-sponsor
  from `/api/sdk/tv/broadcast/subscribe`. Kept as an optional fallback for offline dev work.)
- `campaignId` (**legacy fallback**) — only consulted if `broadcastId` is absent. Will not
  resolve a real broadcast in v2; kept for back-compat with the old v1 demo flow.
- `userId` (optional; host usually sets via `configureFromBundle(userIdOverride:)`)
- `environment` (`development` or `testing`, optional)
- optional endpoint overrides:
  - `backendUrl`
  - `webSocketUrl`
  - `commerceUrl`
  - `devBackendURL`
  - `devWebSocketBaseURL`
  - `devCommerceURL`

`VioTV.connect()` resolution order:
1. If the caller passes `VioTV.connect(broadcastId:)` explicitly, that value wins.
2. Otherwise, `broadcastId` from `vio-config.json`.
3. Otherwise, `campaignId` stringified (legacy — logs a warning).
4. Otherwise, no-op with a console note.

Environment values accepted by Core:

- `development`
- `testing`

Default endpoints:

- `development`
  - backend: `https://api-local-angelo.vio.live`
  - websocket: `wss://api-local-angelo.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`
- `testing`
  - backend: `https://api-dev.vio.live`
  - websocket: `wss://api-dev.vio.live/ws`
  - commerce: `https://graph-ql-dev.vio.live/graphql`

## Where to implement changes

- New transport/event parsing: `VioTVCore/Managers/VioTVWebSocketManager.swift`
- New shared data fields: `VioTVCore/Models/VioTVModels.swift` / `VioTVCore/Models/VioTVSponsor.swift`
- New subscribe / cart-intent behavior: `VioTVCore/VioTVManager.swift`
- New session lifecycle (heartbeat / end): `VioTVCore/Managers/VioTVSessionManager.swift`
- New Commerce fields/query: `VioTVCommerce/VioTVCommerceService.swift`
- New overlay visual/interaction: `VioTVUI/VioTVShoppableOverlay.swift`
- New public API surface: `VioTV/VioTV.swift`

## Guardrails

- Keep Core free from SwiftUI imports.
- Keep UI free from direct networking code.
- Do not reintroduce config parsing in demo views.
- Do not trigger `onCartIntent` on failed HTTP responses.
- Preserve `campaignId` from incoming events to avoid invalid cart-intent routes.
- `cart-intent` must POST to `/api/sdk/tv/cart-intent` (not the legacy mobile endpoint) so the
  backend persists with `source_activation_id` and forwards to the mobile.
- Never log the raw `commerce.apiKey` — they're sponsor-sensitive.
- `VioTVSessionManager` is the single owner of heartbeat / end; don't send `/session/*` from
  anywhere else.

## Demo app — exercising the subscribe soft-miss path

`Demo/tv2demo-appletv` is modelled after a real TV2-style integration: the bundled
`vio-config.json` carries **only credentials** (`apiKey`, `environment`, endpoint
overrides) — intentionally no `broadcastId`, because a real TV app receives its
broadcast ids at runtime from its own catalog backend, not from a local config file.

The app boots into `BroadcastPickerView` (wired from `ContentView`). The picker
offers two cards — each card owns the id it would have received from the host's
catalog — and both navigate to the same `TVPlayerView` with different
`broadcastId` values:

- **Broadcast registrado** → `"barcelona-psg-2026-03-03"`
  Backend responds `{ subscribed: true, ... }`; WebSocket opens, heartbeat starts,
  overlay renders on shoppable_ad events.

- **Broadcast desconocido** → `"broadcast-no-existe-demo"`
  Backend responds `{ subscribed: false, reason: "broadcast_not_registered_for_client_app" }`.
  `InteractiveAds_vioApp` has `VioTV.onSubscriptionFailed` wired, so the soft-miss
  reason is printed to the console; the SDK stays idle, the WebSocket is never opened,
  and no overlay will ever appear. Use this to verify partner apps don't crash when
  Vio doesn't recognise the partner's content id.

`TVPlayerView` accepts `broadcastId: String` as an init parameter and calls
`VioTV.connect(broadcastId: broadcastId)` in `onAppear` + `VioTV.disconnect()` in
`onDisappear`. It also exposes a top-left "Volver" button that uses
`@Environment(\.dismiss)` to pop back to the picker — tapping it triggers
`onDisappear`, which closes the session cleanly (WS shut, `POST /session/end`).

The `defaultBroadcastId` path (loaded from `vio-config.json`'s `broadcastId` key)
still exists in the SDK as a convenience for simpler apps that hardcode a single
broadcast, but the TV2 demo doesn't use it — exactly so the integration surface
matches what a real partner would do.

## Validation checklist before PR

- `swift build`
- `swift test`
- Manual demo smoke check:
  - config loads from bundle
  - WebSocket connect/disconnect works
  - overlay appears on event
  - cart-intent callback fires only on 2xx
