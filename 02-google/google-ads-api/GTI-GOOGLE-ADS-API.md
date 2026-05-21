---
title: GTI · Google Ads API + Google Ads MCP Server
version: 1.0.0
date: 2026-05-21
source: https://github.com/googleads/google-ads-mcp
stars: 530
language: Python
license: Apache 2.0
status: DISPONIBLE — MCP Server oficial + API Discovery Document
---

# GTI · Google Ads API + Google Ads MCP Server

> Google Ads tiene un **MCP Server oficial** (530⭐) que permite a agentes LLM consultar y gestionar campañas de Google Ads directamente.

---

## 1. Google Ads MCP Server ⭐

### Info

| Campo | Valor |
|---|---|
| **Repo** | `googleads/google-ads-mcp` |
| **Stars** | 530 |
| **Lenguaje** | Python |
| **Transporte** | stdio o streamable-http (con OAuth proxy) |
| **Licencia** | Apache 2.0 |
| **Requiere** | Google Ads Developer Token + OAuth2 |

### Tools del MCP Server

| Tool | Descripción |
|---|---|
| `search` | Ejecuta queries GAQL (Google Ads Query Language) contra la cuenta |
| `get_resource_metadata` | Metadata de recursos (campaign, ad_group, etc.) |
| `list_accessible_customers` | Lista cuentas de Google Ads accesibles |

### Resources del MCP Server

| Resource | Descripción |
|---|---|
| `discovery-document` | Documento de discovery completo de la API |
| `metrics` | Métricas disponibles para reporting |
| `segments` | Segmentos disponibles para reporting |
| `release-notes` | Notas de la última versión |

### Setup para ALIUN

```bash
# 1. Instalar
pipx install google-ads-mcp

# 2. Configurar (variables de entorno)
GOOGLE_ADS_DEVELOPER_TOKEN=xxx
GOOGLE_ADS_CLIENT_ID=xxx
GOOGLE_ADS_CLIENT_SECRET=xxx
GOOGLE_ADS_REFRESH_TOKEN=xxx
GOOGLE_ADS_LOGIN_CUSTOMER_ID=xxx  # Manager account

# 3. Conectar a Hermes MCP Client
# Añadir a config.yaml como servidor MCP externo
```

---

## 2. Google Ads API (REST/gRPC)

### Arquitectura

```
Google Ads Account
  ├── Customer (cuenta operativa)
  │     ├── Campaign (objective: PERFORMANCE_MAX, SEARCH, DISPLAY...)
  │     │     ├── AdGroup (targeting + bids)
  │     │     │     ├── AdGroupAd (ad creative)
  │     │     │     └── AdGroupCriterion (keywords, audiences)
  │     │     └── CampaignBudget
  │     ├── ConversionAction (tracking de conversiones)
  │     ├── AudienceSegment (custom segments)
  │     └── Asset (images, videos, text)
  │
  └── Manager Customer (cuenta MCC — multiple clients)
```

### Versión Actual

| Campo | Valor |
|---|---|
| **Versión** | v19 |
| **Protocolo** | gRPC + REST |
| **Query Language** | GAQL (Google Ads Query Language) |
| **Auth** | OAuth 2.0 + Developer Token |
| **Rate Limits** | 2,000 operations/sec, 30,000/day (basic) |

### Objetivos de Campaign para ALIUN

| Objetivo | Uso | Canal |
|---|---|---|
| **PERFORMANCE_MAX** | Máximo rendimiento cross-channel | Search + Display + YouTube + Maps |
| **SEARCH** | Intención de búsqueda hotelera | Google Search |
| **DISPLAY** | Remarketing visual | Gmail, YouTube, sitios partners |
| **HOTEL** | Hotel Ads (Price Ads) | Google Hotels |
| **VIDEO** | YouTube video ads | YouTube |
| **LOCAL** | Promoción local RD | Google Maps |

---

## 3. Google Hotel Ads ⭐ (Especial para ALIUN)

### Concepto
Google Hotel Ads muestra precios de hoteles directamente en los resultados de búsqueda de Google Hotels. **ALIUN puede aparecer ahí.**

### Flujo
```
1. Hotel Price Feed → Google (via Hotel Center or API)
   hotels_master → price feed XML/JSON
   
2. Usuario busca hotel en Google
   Google.com/travel → muestra ALIUN price
   
3. Click → landing page (aliuntravelsrl.com/hotel/{slug})
   o → Google Booking (si integrado)

4. Booking → confirmación → tracking
   Google Ads Conversion Action → atribución
```

### Requisitos
- Google Hotel Center account
- Hotel Price Feed (XML o API)
- Pricing accuracy (±5% del precio real)
- Integration: Price Ads o Booking Ads

---

## 4. Flujo ALIUN: Google Ads → CRM → Venta

```
1. CREAR CAMPAIGN (objective: SEARCH o PERFORMANCE_MAX)
   Google Ads → Keywords: "hotel punta cana", "hotel santo domingo"

2. USUARIO HACE CLICK
   Ad → aliuntravelsrl.com → Widget → n8n → crm_leads

3. LEAD EN PIPELINE
   crm_leads (source='google_ads') → WhatsApp → vendedor

4. CONVERSIÓN
   Lead deposita → Google Ads Conversion Action → atribución

5. OPTIMIZACIÓN
   Google Ads MCP → search(GAQL) → métricas → War Room
   Performance Max → auto-optimización cross-channel
```

---

## 5. GAQL — Google Ads Query Language

### Ejemplos para ALIUN

```sql
-- Campañas activas con métricas
SELECT campaign.name, campaign.status, 
       metrics.impressions, metrics.clicks, 
       metrics.cost_micros, metrics.conversions
FROM campaign
WHERE campaign.status = 'ENABLED'
  AND segments.date DURING LAST_7_DAYS

-- Keywords con mejor CTR
SELECT ad_group_criterion.keyword.text, 
       metrics.ctr, metrics.average_cpc
FROM ad_group_criterion
WHERE ad_group_criterion.type = 'KEYWORD'
ORDER BY metrics.ctr DESC
LIMIT 20

-- Audience performance
SELECT audience.resource_name, 
       metrics.cost_micros, metrics.conversions
FROM audience
WHERE segments.date DURING LAST_30_DAYS
```

---

## 6. Developer Assistant

| Info | Valor |
|---|---|
| **Repo** | `googleads/google-ads-api-developer-assistant` |
| **Stars** | 78 |
| **Tipo** | Asistente LLM para Google Ads API |
| **Uso** | Generar queries GAQL, debug API issues |

---

## 7. Checklist de Implementación ALIUN

### Fase 0 — Cuenta
- [ ] Google Ads account creada
- [ ] Developer Token obtenido (Explorer access mínimo)
- [ ] OAuth 2.0 credentials configuradas
- [ ] Google Ads MCP Server conectado a Hermes

### Fase 1 — Search Campaign
- [ ] Keywords investigación (hotel + RD + destinations)
- [ ] Crear Search campaign con ad groups
- [ ] Landing pages por hotel (aliuntravelsrl.com/hotel/{slug})
- [ ] Conversion Action configurada

### Fase 2 — Hotel Ads
- [ ] Hotel Center account
- [ ] Price Feed desde hotels_master
- [ ] Hotel Ads campaign
- [ ] Price accuracy verificación

### Fase 3 — Performance Max
- [ ] Assets (imágenes, textos, videos)
- [ ] Audience signals (from crm_leads data)
- [ ] Performance Max campaign
- [ ] Budget optimization

### Fase 4 — Reporting
- [ ] Google Ads MCP → War Room metrics
- [ ] GAQL queries automatizadas
- [ ] ROAS tracking por campaign
- [ ] Cross-channel attribution (Meta + Google)

---

## 8. Recursos

| Recurso | URL |
|---|---|
| Google Ads MCP | `github.com/googleads/google-ads-mcp` |
| Developer Assistant | `github.com/googleads/google-ads-api-developer-assistant` |
| API Docs | `developers.google.com/google-ads/api` |
| Hotel Ads | `developers.google.com/hotel-ads` |
| GAQL Reference | `developers.google.com/google-ads/api/query-builder` |
| Discovery Document | Incluido en MCP server |

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*Basado en googleads/google-ads-mcp (530⭐) + Google Ads API v19*
