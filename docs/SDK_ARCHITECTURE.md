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
  "campaignId": 36,
  "product": {
    "id": "408895",
    "title": "Samsung 85 Neo QLED 4K TV",
    "images": [{ "url": "https://...", "order": 0 }],
    "price": { "amount": 17990, "amount_incl_taxes": 17990, "currency_code": "NOK" }
  }
}
```

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
- `commerceApiKey` (**deprecated / dev-only** — production commerce keys come per-sponsor
  from `/api/sdk/tv/broadcast/subscribe`. Kept as an optional fallback for offline dev work.)
- `campaignId` (optional but recommended; used only when the host calls bare `VioTV.connect()`)
- `userId` (optional; host usually sets via `configureFromBundle(userIdOverride:)`)
- `environment` (`development` or `testing`, optional)
- optional endpoint overrides:
  - `backendUrl`
  - `webSocketUrl`
  - `commerceUrl`
  - `devBackendURL`
  - `devWebSocketBaseURL`
  - `devCommerceURL`

If `campaignId` is missing, consumers must call `VioTV.connect(broadcastId:)` explicitly.
Recommended usage from host apps is always `connect(broadcastId:)` with the partner-internal
broadcast id — that's what the subscribe endpoint validates against.

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

## Validation checklist before PR

- `swift build`
- `swift test`
- Manual demo smoke check:
  - config loads from bundle
  - WebSocket connect/disconnect works
  - overlay appears on event
  - cart-intent callback fires only on 2xx
