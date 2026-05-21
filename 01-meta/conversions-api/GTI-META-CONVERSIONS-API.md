---
title: GTI · Meta Conversions API (CAPI) + Pixel
version: 1.0.0
date: 2026-05-21
source: https://github.com/facebook/capi-param-builder
language: Node.js, Python, PHP, Java, Ruby
license: MIT
status: DISPONIBLE — SDK + Param Builder
---

# GTI · Meta Conversions API (CAPI) + Pixel

> La Conversions API envía eventos de conversión desde el servidor (no del browser) a Meta para atribución de ads. Crítico para ALIUN: sin CAPI, Meta no puede optimizar hacia ventas reales.

---

## 1. Arquitectura Dual Tracking

```
┌─────────────────────────┐
│   aliuntravelsrl.com    │
│  ┌───────────────────┐  │
│  │   Meta Pixel (JS) │──┼──▶ events.facebook.com (client-side)
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │   Server (n8n)    │──┼──▶ graph.facebook.com/{pixel_id}/events (server-side)
│  │   Conversions API │  │
│  └───────────────────┘  │
└─────────────────────────┘
         │                      │
         └──── event_id ────────┘    ← deduplication key
                    │
          Meta Ads Manager
        (atribución unificada)
```

### ¿Por qué AMBOS?
- **Pixel solo**: pierde ~30% de datos por ad blockers, ITP, app browsers
- **CAPI solo**: pierde datos del cliente (browser context, fbclid)
- **Ambos + deduplication**: máxima cobertura + atribución precisa

---

## 2. CAPI Param Builder SDK

### Instalación (Node.js)
```bash
npm install @facebook/capi-param-builder
```

### Instalación (Python)
```bash
pip install facebook-capi-param-builder
```

### Uso en ALIUN (n8n Function Node)
```javascript
const { CapiParamBuilder } = require('@facebook/capi-param-builder');

// Cuando un lead se registra
const builder = new CapiParamBuilder({
  pixelId: 'PIXEL_ID',
  accessToken: 'ACCESS_TOKEN',
});

builder
  .setEventName('Lead')
  .setEventId('lead_12345')           // deduplication key
  .setEmail('cliente@email.com')      // hashed automatically
  .setPhone('8495833500')             // hashed automatically
  .setCustomData({
    hotel: 'Hotel XYZ',
    check_in: '2026-06-15',
    value: 2500,
    currency: 'USD'
  });

const payload = builder.build();
// POST to graph.facebook.com/v23.0/{pixel_id}/events
```

### Hashing automático
El SDK hashea automáticamente: email, phone, fn, ln, ct, st, zp, country, db, ge
- SHA-256 → lowercase → sin espacios
- Nunca enviar PII sin hash

---

## 3. Eventos ALIUN — Mapeo CRM → CAPI

| crm_leads stage | CAPI Event | custom_data |
|---|---|---|
| `nuevo` | `Lead` | source, hotel_interest |
| `contactado` | — | — |
| `cotizado` | `AddToCart` | hotel, value, currency |
| `negociando` | `InitiateCheckout` | hotel, value, currency |
| `cerrado_ganado` | `Purchase` | hotel, value, currency, booking_id |
| `cerrado_perdido` | — | — (no enviar evento) |

### Endpoint CAPI
```
POST https://graph.facebook.com/v23.0/{pixel_id}/events
Headers:
  Authorization: Bearer {access_token}
  Content-Type: application/json

Body:
[
  {
    "event_name": "Purchase",
    "event_time": 1716307200,
    "event_id": "booking_789",
    "event_source_url": "https://aliuntravelsrl.com/hotel/...",
    "action_source": "website",
    "user_data": {
      "em": ["hash_email"],
      "ph": ["hash_phone"]
    },
    "custom_data": {
      "currency": "USD",
      "value": 2500,
      "content_ids": ["hotel_123"],
      "content_type": "hotel",
      "content_name": "Hotel XYZ Punta Cana"
    }
  }
]
```

---

## 4. Deduplication

### Regla
- `event_id` = mismo valor en Pixel JS y CAPI
- Meta usa `event_id` + `event_name` + timestamp (±48h) para deduplicar
- Si ambos envían el mismo evento con mismo `event_id`, Meta cuenta 1

### Implementación
```
Pixel (client):
  fbq('track', 'Purchase', {value: 2500, currency: 'USD'}, {eventID: 'booking_789'});

CAPI (server):
  POST event_name='Purchase', event_id='booking_789'
```

---

## 5. Conversion Leads (Lead → Conversión Feedback)

### Qué hace
Informa a Meta cuándo un lead de Lead Ads se convirtió en venta. Meta optimiza automáticamente.

### Endpoint
```
POST https://graph.facebook.com/v23.0/{ad_id}/conversions
```

### Payload
```json
{
  "data": [{
    "event_name": "Lead",
    "event_time": 1716307200,
    "user_data": {
      "lead_id": "LEAD_ID_FROM_FORM",
      "phone_number": "8495833500"
    },
    "custom_data": {
      "event_name": "OffsiteConversion",
      "value": 2500,
      "currency": "USD"
    }
  }]
}
```

### En ALIUN
```
1. Lead form Meta → lead_id almacenado en crm_leads.meta_lead_id
2. Lead avanza pipeline → cerrado_ganado
3. n8n trigger → POST Conversion Leads API con lead_id + value
4. Meta optimiza campañas para leads que más convierten
```

---

## 6. Checklist ALIUN

### Pixel Setup
- [ ] Crear Pixel en Meta Business Suite
- [ ] Instalar Pixel JS en aliuntravelsrl.com (via GTM o directo)
- [ ] Verificar Pixel con Meta Pixel Helper (Chrome extension)

### CAPI Setup
- [ ] Generar Access Token (Events Manager → Settings → Conversions API)
- [ ] Instalar capi-param-builder SDK en n8n
- [ ] Crear workflow n8n: crm_leads update → CAPI event
- [ ] Verificar en Events Manager → Test Events

### Deduplication
- [ ] event_id matching entre Pixel JS y CAPI
- [ ] Verificar en Events Manager → deduplication rate > 90%

### Conversion Leads
- [ ] Almacenar meta_lead_id en crm_leads
- [ ] Workflow n8n: stage='cerrado_ganado' → POST Conversion Leads
- [ ] Verificar en Ads Manager → "Optimize for conversion leads"

---

## 7. Recursos

| Recurso | URL |
|---|---|
| CAPI Param Builder | `github.com/facebook/capi-param-builder` |
| Conversion Leads | `github.com/facebook/Conversion-Leads-Salesforce-APEX` |
| Pixel GTM Template | `github.com/facebook/GoogleTagManager-WebTemplate-For-FacebookPixel` |
| CAPI Docs | `developers.facebook.com/docs/marketing-api/conversions-api` |
| Events Manager | `business.facebook.com/events_manager` |

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*Basado en facebook/capi-param-builder + Meta Conversions API docs*
