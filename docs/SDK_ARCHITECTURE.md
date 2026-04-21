# SDK Architecture Guide

This document explains how the consolidated SDK is structured, how data flows at runtime, and where to add new behavior safely.

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

## Runtime sequence

1. App calls `VioTV.configure(...)` or `VioTV.configureFromBundle(...)`.
2. App starts runtime with `VioTV.connect(...)`.
3. Core WebSocket manager receives backend messages:
   - accepts `type: "shoppable_ad"` directly
   - accepts `type: "product"` and maps to `ShoppableAdEvent`
4. Core publishes `activeAd`.
5. UI overlay renders when `activeAd != nil`.
6. On CTA tap, UI calls `sendCartIntent`.
7. Core POSTs cart-intent and only reports success callback on 2xx.
8. Facade may enrich incomplete product payloads through Commerce.

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

- `apiKey`
- `commerceApiKey`
- `campaignId` (optional but recommended)
- `userId` (optional)
- `environment` (`development` or `testing`, optional)
- optional endpoint overrides:
  - `backendUrl`
  - `webSocketUrl`
  - `commerceUrl`
  - `devBackendURL`
  - `devWebSocketBaseURL`
  - `devCommerceURL`

If `campaignId` is missing, consumers must call `VioTV.connect(broadcastId:)` explicitly.

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
- New shared data fields: `VioTVCore/Models/VioTVModels.swift`
- New cart-intent behavior: `VioTVCore/VioTVManager.swift`
- New Commerce fields/query: `VioTVCommerce/VioTVCommerceService.swift`
- New overlay visual/interaction: `VioTVUI/VioTVShoppableOverlay.swift`
- New public API surface: `VioTV/VioTV.swift`

## Guardrails

- Keep Core free from SwiftUI imports.
- Keep UI free from direct networking code.
- Do not reintroduce config parsing in demo views.
- Do not trigger `onCartIntent` on failed HTTP responses.
- Preserve `campaignId` from incoming events to avoid invalid cart-intent routes.

## Validation checklist before PR

- `swift build`
- `swift test`
- Manual demo smoke check:
  - config loads from bundle
  - WebSocket connect/disconnect works
  - overlay appears on event
  - cart-intent callback fires only on 2xx
