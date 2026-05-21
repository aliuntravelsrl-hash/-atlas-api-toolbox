---
title: GTI · TikTok Marketing API
version: 1.0.0
date: 2026-05-21
source: https://business-api.tiktok.com/portal
status: 🔲 PENDING — No OpenAPI spec publicado
priority: BAJA (después de Meta + Google)
---

# GTI · TikTok Marketing API

> TikTok NO publica su API como OpenAPI spec. Documentación solo en su portal de business.
> Este GTI es un placeholder hasta que ALIUN active TikTok como fuente de tráfico.

---

## 1. Información General

| Campo | Valor |
|---|---|
| **Portal** | `business-api.tiktok.com/portal` |
| **Versión** | v1.3 (current) |
| **Autenticación** | OAuth 2.0 via Business Center |
| **Rate Limit** | 10 queries/sec (sandbox), 100/sec (production) |
| **Specs en GitHub** | ❌ Ninguno publicado |
| **Postman** | Disponible dentro del portal (no público) |

---

## 2. Arquitectura de Ads (Jerarquía TikTok)

```
TikTok Business Center
  └── Advertiser Account
        ├── Campaign (objective: TRAFFIC, LEAD_GEN, CONVERSIONS)
        │     └── Ad Group (targeting, budget, placement)
        │           └── Ad (creative: video, image, spark ads)
        │
        ├── Audience (custom, lookalike)
        ├── Pixel (TikTok Pixel — tracking)
        └── Lead Form (lead gen forms)
```

---

## 3. Endpoints Clave (desde documentación del portal)

### Campaign Management
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/campaign/get/` | Info de campaña |
| POST | `/campaign/create/` | Crear campaña |
| POST | `/campaign/update/` | Actualizar campaña |
| GET | `/campaign/list/` | Listar campañas |

### Ad Group Management
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/adgroup/get/` | Info de ad group |
| POST | `/adgroup/create/` | Crear ad group |
| POST | `/adgroup/update/` | Actualizar ad group |

### Ad Management
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/ad/get/` | Info de anuncio |
| POST | `/ad/create/` | Crear anuncio |
| POST | `/ad/update/` | Actualizar anuncio |

### Reporting
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/report/integrated/get/` | Reporte de rendimiento |
| GET | `/report/audience/get/` | Reporte de audiencia |

### Lead Generation
| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/lead/` | Obtener leads |
| POST | `/lead/webhook/` | Configurar webhook |

### Audience
| Método | Endpoint | Descripción |
|---|---|---|
| POST | `/audience/create/` | Custom audience |
| POST | `/audience/lookalike/create/` | Lookalike audience |

---

## 4. TikTok Pixel + Events API

### Arquetiqueta (equivalente a CAPI)
```
TikTok Pixel (client-side)
  ├── events: PageView, ViewContent, Lead, Purchase
  └── Advanced Matching: email, phone

Events API (server-side)
  ├── POST /event/track/
  ├── Igual que Conversions API de Meta
  └── Deduplication via event_id
```

---

## 5. Flujo ALIUN: TikTok Ads → CRM → Venta

```
1. CREAR CAMPAIGN (objective: LEAD_GEN)
   TikTok Ads → Lead Form (hotel, fechas, teléfono)

2. LEAD ENTRA
   Lead Form → Webhook → n8n → atlas-sales-mcp
   registrar_lead(source='tiktok_ad')

3. LEAD EN PIPELINE
   crm_leads → WhatsApp → vendedor → cotización

4. CONVERSIÓN
   Events API → atribución → optimización
```

---

## 6. Diferencias vs Meta Ads

| Aspecto | Meta | TikTok |
|---|---|---|
| **OpenAPI Spec** | ✅ 995 JSON specs | ❌ Solo portal |
| **MCP Server** | ❌ No existe | ❌ No existe |
| **Audience** | Facebook + Instagram | TikTok global |
| **Formato** | Image, Video, Carousel, Lead Form | Video-first, Spark Ads |
| **Demografía** | 25-55+ | 18-35 dominante |
| **Hotel intent** | Alto (viajeros buscan hoteles) | Medio (descubrimiento) |
| **Lead Quality** | Alto (intent-based) | Medio (discovery-based) |
| **ROAS típico** | 3-8x (travel vertical) | 2-5x (travel vertical) |

---

## 7. Cuándo activar TikTok

**PREREQUISITOS:**
1. ✅ Meta Ads operacional (Lead Gen + Traffic)
2. ✅ Google Ads operacional (Search + Hotel)
3. ✅ CRM funcional con pipeline
4. ✅ Pixel + Conversions API funcionando en Meta
5. ✅ Budget disponible para nuevo canal

**RECOMENDACIÓN:** Activar TikTok solo cuando Meta + Google estén generando leads y conversions de forma estable. TikTok es discovery-based (no intent-based) → requiere más creatividad y testing.

---

## 8. Checklist de Implementación ALIUN

### Fase 0 — Cuenta
- [ ] TikTok Business Center account
- [ ] Advertiser account creado
- [ ] Pixel instalado en aliuntravelsrl.com
- [ ] OAuth 2.0 configurado

### Fase 1 — Video Ads
- [ ] Crear videos de hotel (15-30 sec, vertical)
- [ ] Campaign TRAFFIC → aliuntravelsrl.com
- [ ] TikTok Pixel + Events API

### Fase 2 — Lead Gen
- [ ] Lead Form creado
- [ ] Webhook → n8n → registrar_lead
- [ ] Pipeline integrado

### Fase 3 — Reporting
- [ ] Reporting API → War Room métricas
- [ ] Cross-channel attribution (Meta + Google + TikTok)

---

## 9. Recursos

| Recurso | URL |
|---|---|
| Business API Portal | `business-api.tiktok.com/portal` |
| API Docs | `business-api.tiktok.com/portal/docs/id/1739584855420929` |
| Sandbox | `business-api.tiktok.com/portal/docs/id/1735791367990786` |
| TikTok for Business | `ads.tiktok.com` |

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*TikTok Marketing API · Placeholder — sin spec oficial publicado*
