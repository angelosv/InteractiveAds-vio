# CONTEXT.md — InteractiveAds-vio (Apple TV Demo)

> Fuente de verdad para Claude / agentes. Leer antes de tocar cualquier archivo.

---

## ¿Qué es esto?

Demo de concepto para TV2 y Viaplay que muestra cómo Vio.live puede convertir los anuncios de pausa en **shoppable ads interactivos** en Apple TV.

Durante la pausa de un partido, el espectador ve un anuncio del sponsor (Elkjøp). En ese momento aparece una card de producto en la **esquina inferior izquierda** con datos reales de Commerce (nombre, imagen, precio en NOK). El usuario puede navegar con el mando de Apple TV y ver más información.

---

## Repo

- **GitHub:** https://github.com/angelosv/InteractiveAds-vio
- **Plataforma:** tvOS (Apple TV)
- **Lenguaje:** Swift / SwiftUI
- **Sin dependencias externas** — todo vanilla SwiftUI + URLSession

---

## Configuración

### vio-config.json (bundle)
```json
{
  "apiKey": "tv2_api_key_91b4fbf634af4bc5",
  "campaignId": 36,
  "backendUrl": "https://api-dev.vio.live",
  "webSocketUrl": "wss://api-dev.vio.live/ws/36",
  "contentId": "barcelona-psg-2026-03-03",
  "country": "NO"
}
```

### demo-static-data.json (bundle)
Contiene: sponsor (Elkjøp), datos del partido (Barcelona 2-1 PSG, min 65, PAUSE) y 2 productos demo de fallback.

---

## Arquitectura

```
VioTVConfigLoader      → carga vio-config.json + demo-static-data.json al arrancar
VioTVWebSocketManager  → conecta al WS del backend, escucha evento "shoppable_ad"
VioCommerceService     → fetch GraphQL real de producto desde Commerce
TVPlayerView           → pantalla principal: partido en pausa + anuncio Elkjøp
TVProductCard          → card de producto, esquina inferior izquierda
```

### Flujo completo
1. App arranca → VioTVConfigLoader.load() lee los JSON del bundle
2. TVPlayerView aparece: fondo oscuro, anuncio Elkjøp, score bar Barcelona 2-1 PSG
3. VioTVWebSocketManager.connect(to: webSocketUrl) → conecta al backend
4. Si llega evento "shoppable_ad" por WS O se pulsa "Simular anuncio":
   - Se extrae el productId del evento (fallback: 408895)
   - VioCommerceService.fetchProduct(id:) hace fetch GraphQL real
   - TVProductCard aparece con slide-up en esquina inferior izquierda
   - Auto-dismiss a los 15 segundos

---

## Commerce API

- **Endpoint GraphQL:** https://graph-ql-dev.vio.live/graphql
- **Auth:** header "Authorization: <apiKey>"
- **API Key:** KCXF10Y-W5T4PCR-GG5119A-Z64SQ9S (leerla de config, nunca hardcodear)
- **countryCode:** NO, **currencyCode:** NOK

### Productos disponibles (demo Elkjøp)
| ID     | Nombre                          | Precio    |
|--------|---------------------------------|-----------|
| 408841 | FC Barcelona Jersey 24/25       | 759 kr    |
| 408874 | PSG Away Jersey 24/25           | 999 kr    |
| 408895 | Samsung 85" Neo QLED 4K TV      | 17.990 kr |
| 408896 | Samsung Soundbar HW-S710D       | 6.999 kr  |

### Query GraphQL
```graphql
{
  Channel {
    GetProductById(id: "408895", countryCode: "NO", currencyCode: "NOK") {
      id
      name
      images { url order }
      price { amount amount_incl_taxes currency_code }
    }
  }
}
```

---

## Backend / WebSocket

- **WS URL:** wss://api-dev.vio.live/ws/36 (campaña 36 = TV2)
- **Evento que escucha:** "shoppable_ad"
- **Formato del evento:**
```json
{
  "type": "shoppable_ad",
  "product": {
    "id": "408895",
    "name": "Samsung 85 Neo QLED 4K TV",
    "price": 17990,
    "currency": "NOK",
    "imageUrl": "https://..."
  },
  "sponsor": {
    "name": "Elkjøp",
    "logoUrl": "https://api-dev.vio.live/objects/uploads/adc65620-01ff-4c66-a7e2-de456495b9d1",
    "primaryColor": "#003087"
  }
}
```

AVISO: El endpoint POST /api/broadcasts/:id/shoppable-ad en el backend aun NO existe.
Para la demo se usa el boton "Simular anuncio" que llama a simulateShoppableAd() localmente.

---

## Sponsor

- **Nombre:** Elkjøp
- **Logo URL:** https://api-dev.vio.live/objects/uploads/adc65620-01ff-4c66-a7e2-de456495b9d1
- **Color primario:** #003087 (azul Elkjøp)

---

## UX / Diseño

- **Fondo:** gradiente oscuro #0D0D26 a #1A0D33 (simula pausa de partido)
- **Score bar:** centrado, Barcelona 2 - 1 PSG, min 65, badge PAUSE en rojo
- **Anuncio:** logo Elkjøp centrado + "Kampanje — opptil 40% rabatt"
- **Product card:** esquina inferior izquierda, 420x120pt, fondo rgba oscuro, slide-up spring
- **CTA:** boton "Se mer →" que se pone amarillo al recibir foco del mando
- **Auto-dismiss:** 15 segundos
- **Foco:** al aparecer la card, el foco del mando va al boton CTA automaticamente

---

## Reglas de desarrollo

1. NUNCA hardcodear el Commerce API key — leerlo de vio-config.json
2. NUNCA hardcodear URLs — leerlas de vio-config.json
3. Sin dependencias externas — solo SwiftUI + URLSession + Foundation
4. tvOS unicamente — no Mac, no iPad, no iPhone
5. print() con prefijo [VioTV] esta bien en este repo (no hay VioLogger aqui)
6. Precios formateados: separador de miles punto, formato "kr X.XXX,-"

---

## Estado actual (2026-03-05)

### IMPLEMENTADO
- Pantalla de pausa con anuncio Elkjøp + score bar
- WS conectado al backend real (/ws/36)
- VioCommerceService: fetch GraphQL real (nombre, imagen, precio NOK real)
- TVProductCard en esquina inferior izquierda con animacion + foco tvOS
- Boton "Simular anuncio" para demo sin backend activo
- Auto-dismiss 15 segundos

### BACKLOG (sin prioridad inmediata)
- Carrusel horizontal de multiples productos (navegar con mando)
- Handoff TV a iPhone cuando usuario selecciona producto
- Endpoint POST /api/broadcasts/:id/shoppable-ad en Replit para trigger real

---

## Relacion con VioSwiftSDK

Este repo es INDEPENDIENTE del SDK. No importa VioSwiftSDK como dependencia.
Implementa sus propios servicios simplificados para tvOS.
Si en el futuro se quiere integrar el SDK real, crear un target tvOS en VioSwiftSDK.

---

## Campaña TV2

- **API Key:** tv2_api_key_91b4fbf634af4bc5
- **Campaign ID:** 36
- **Broadcast activo:** barcelona-psg-2026-03-03 (status: live)
- **Sponsor:** Elkjøp
- **Backend:** https://api-dev.vio.live
