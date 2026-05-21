---
title: GTI · Meta Marketing API (MAPI)
version: 1.0.0
date: 2026-05-21
source: https://github.com/facebook/facebook-business-sdk-codegen
spec_count: 995 JSON specs (446 relevant to ALIUN)
postman: MAPI-Public.postman_collection.json (89KB, 10 folders, 47 endpoints)
status: DISPONIBLE — Specs + Postman + SDK Codegen
---

# GTI · Meta Marketing API (MAPI)

> Referencia cognitiva del Meta Marketing API — la plataforma de advertising de Meta (Facebook + Instagram + WhatsApp + Messenger).
> Fuente: `facebook/facebook-business-sdk-codegen` — repo oficial de codegen con 995 specs JSON.

---

## 1. Información General

| Campo | Valor |
|---|---|
| **Nombre** | Meta Marketing API (MAPI) |
| **Versión API** | v23.0 |
| **Servidor** | `https://graph.facebook.com/{Version}/` |
| **Autenticación** | OAuth 2.0 + Access Token |
| **SDKs oficiales** | Python, Node.js, PHP, Java, Ruby |
| **Repo specs** | `facebook/facebook-business-sdk-codegen` |
| **Postman** | 89KB, 47 endpoints en 10 carpetas |
| **Licencia** | MIT + Platform Terms |

### URL Base

```
https://graph.facebook.com/v23.0/{Ad-Account-ID}/...
```

---

## 2. Arquitectura de Ads (Jerarquía Meta)

```
Business Manager
  └── Ad Account (act_{ID})
        ├── Campaign (objective: CONVERSIONS, LEAD_GEN, TRAFFIC...)
        │     └── Ad Set (targeting, budget, placement)
        │           └── Ad (creative + tracking)
        │                 └── Ad Creative (image, video, carousel)
        │
        ├── Custom Audiences (lookalike, website, lead form)
        ├── Pixel (tracking + Conversions API)
        ├── Product Catalog (hotel inventory)
        └── Lead Forms (CRM entry point)
```

---

## 3. Postman Collection — Carpetas

| Carpeta | Endpoints | Uso ALIUN |
|---|---|---|
| **Campaign** | 12 CRUD | Crear/editar campañas (LEAD_GEN, CONVERSIONS) |
| **AdCreative** | 3 | Creatividades de anuncios (imágenes, videos) |
| **AdSets** | 7 | Targeting, presupuesto, programación |
| **Ad** | 7 | Gestión de anuncios individuales |
| **Insights API** | 6 | Métricas de rendimiento (CPC, CTR, ROAS) |
| **Targeting** | 2 | Búsqueda de audiences |
| **AdAccount** | 4 | Info de cuenta, límites, pagos |
| **Users** | 2 | Permisos de usuarios |
| **Conversion** | 2 | Conversions API setup |
| **Pixel** | 2 | Pixel setup + eventos |

---

## 4. Specs Clave para ALIUN (12 archivos descargados)

### 4.1 AdAccount.json (140KB — el más grande)
El objeto central. Todo cuelga de un Ad Account.
- Campos: name, currency, timezone, business, amount_spent, balance, etc.
- Edge: campaigns, adsets, ads, customaudiences, pixels, leadgen_forms

### 4.2 AdCampaignGroup.json (Campaign)
- objective: CONVERSIONS, LEAD_GEN, TRAFFIC, REACH, etc.
- status: ACTIVE, PAUSED, DELETED
- special_ad_categories: HOUSING, CREDIT, EMPLOYMENT, NONE

### 4.3 AdCampaign.json + AdSet.json
- Campaign = objetivo estratégico
- AdSet = targeting + presupuesto + schedule
- Campos targeting: geo_locations, age_min/max, interests, behaviors

### 4.4 AdCreative.json
- Tipo: IMAGE, VIDEO, CAROUSEL, COLLECTION
- Para hoteles: CAROUSEL con múltiples imágenes de hotel
- Dynamic Ads: usa Product Catalog

### 4.5 Lead.json + LeadgenForm.json ⭐ CRM DIRECTO
- Lead = respuesta individual de un formulario
- LeadgenForm = el formulario de lead gen
- Campos: name, email, phone, check_in, check_out, adults
- **CONEXIÓN CRM**: Lead → crm_leads (source='meta_ad')
- Webhook: Lead gen → n8n → atlas-sales-mcp → registrar_lead

### 4.6 AdsPixel.json (16KB)
- Pixel de tracking en aliuntravelsrl.com
- Eventos: PageView, ViewContent, Lead, Purchase, Search
- **CONEXIÓN**: Pixel → Conversions API → atribución de ventas

### 4.7 CustomAudience.json (16KB)
- Tipos: website, lead_form, lookalike, customer_list
- Para ALIUN: lookalike de clientes existentes → más leads calificados

### 4.8 InstagramUser.json
- Instagram Business Account conectado
- Insights, stories, reels

### 4.9 ProductCatalog.json (64KB)
- Catálogo de hoteles para Dynamic Ads
- **CLAVE**: Dynamic Ads for Travel (DAT) → muestra hoteles a quienes buscaron
- Feed: hotels_master → Product Catalog → Dynamic Ads

---

## 5. Flujo ALIUN: Meta Ads → CRM → Venta

```
1. CREAR CAMPAÑA (objective: LEAD_GEN)
   Meta Ads → Lead Form (hotel, fechas, adultos, teléfono)

2. LEAD ENTRA
   LeadgenForm → Webhook → n8n → atlas-sales-mcp
   registrar_lead(full_name, phone, source='meta_ad', hotel_interest)

3. LEAD EN PIPELINE
   crm_leads (stage='nuevo') → Chatwoot/OpenWA → vendedor contacta

4. COTIZACIÓN
   atlas-sales-mcp → calcular_cotizacion → landing_url
   WhatsApp → enviar landing_url al lead

5. CONVERSIÓN
   Lead deposita → deal confirmado → booking
   Pixel + Conversions API → Meta atribuye la venta

6. OPTIMIZACIÓN
   Custom Audience (compradores) → Lookalike → más leads calificados
   Insights API → ROAS por campaña → optimizar presupuesto
```

### Funnel Dual ALIUN

```
CANAL A: Meta Lead Ads
  Ad → Lead Form → n8n → crm_leads → WhatsApp → cotización → booking

CANAL B: Meta Traffic Ads (aliuntravelsrl.com)
  Ad → Website → Widget → n8n → crm_leads → cotización → booking

AMBOS canales → Pixel + Conversions API → atribución → optimización
```

---

## 6. Conversions API + Pixel (Server-Side Tracking)

### Arquitectura de Tracking

```
Cliente (browser)                    Servidor (n8n)
┌──────────────┐                    ┌──────────────┐
│  Meta Pixel  │─── event ────▶    │ Conversions  │
│  (client)    │                   │ API (CAPI)   │
└──────────────┘                    └──────────────┘
       │                                   │
       └──────── deduplication ────────────┘
                        │
                  Meta Ads Manager
                (atribución unificada)
```

### Eventos que ALIUN debe trackear

| Evento | Pixel | CAPI | Valor |
|---|---|---|---|
| `PageView` | ✅ Auto | — | — |
| `ViewContent` | ✅ | ✅ | Hotel viewed |
| `Search` | ✅ | ✅ | Destination query |
| `Lead` | ✅ | ✅ | Lead form submitted |
| `AddToCart` | — | ✅ | Cotización generada |
| `InitiateCheckout` | — | ✅ | Deal created |
| `Purchase` | ✅ | ✅ | Booking confirmed + value |

### Herramienta: capi-param-builder
- SDK oficial para mejorar calidad de parámetros CAPI
- 5 lenguajes servidor: PHP, Java, Node.js, Python, Ruby
- + Client-side JavaScript para match de usuario
- Repo: `facebook/capi-param-builder`

---

## 7. Conversion Leads (Lead → CRM → Meta Optimization)

### Qué hace
Informa a Meta cuando un lead de Facebook se convierte en venta real. Meta usa esta data para optimizar automáticamente hacia leads que más convierten.

### Flujo
```
1. Lead entra por Lead Form (Meta guarda lead_id)
2. Lead → crm_leads → vendedor → cotización → depósito
3. POST a Conversions API:
   {
     "event_name": "Lead",
     "event_id": "{lead_id}",  
     "user_data": { phone, email },
     "custom_data": { "stage": "depositado", "value": 2500 }
   }
4. Meta optimiza: muestra más ads a perfiles similares al que convirtió
```

### Herramienta: Conversion-Leads-Salesforce-APEX
- Referencia de integración (Salesforce) — adaptar para Supabase
- Repo: `facebook/Conversion-Leads-Salesforce-APEX`

---

## 8. Pixel + Google Tag Manager

### Template oficial
- GTM Community Template para Facebook Pixel
- Repo: `facebook/GoogleTagManager-WebTemplate-For-FacebookPixel`
- Soporta: eventos estándar, custom, Advanced Matching, Enhanced Ecommerce, CCPA

### Setup ALIUN
```
aliuntravelsrl.com → GTM Container → Facebook Pixel Template
                                        ├── PageView (auto)
                                        ├── ViewContent (hotel pages)
                                        ├── Lead (widget form)
                                        └── Purchase (booking confirmation)
```

---

## 9. Dynamic Ads for Travel (DAT)

### Concepto
Meta tiene un formato específico para travel: muestra hoteles dinámicamente a usuarios que buscaron pero no reservaron.

### Data Feed
```
hotels_master (Supabase) → Product Catalog (Meta)
  ├── hotel_id → content_id
  ├── name → title  
  ├── slug → link (aliuntravelsrl.com/hotel/{slug})
  ├── gallery_data → image_url
  ├── rates → price
  └── zone → destination
```

### Setup
1. Crear Product Catalog en Meta Business Suite
2. Subir feed via API o scheduled fetch
3. Crear Campaign con objective=CONVERSIONS
4. Ad Set con product_sales_channel=HOTELS
5. Ad usa Dynamic Creative con template de hotel

---

## 10. Checklist de Implementación ALIUN

### Fase 0 — Cuenta
- [ ] Business Manager verificado
- [ ] Ad Account activo con método de pago
- [ ] Pixel creado e instalado en aliuntravelsrl.com
- [ ] Conversions API configurada en n8n

### Fase 1 — Lead Gen Campaign
- [ ] Crear Lead Form (hotel, fechas, adultos, teléfono)
- [ ] Configurar webhook Lead → n8n
- [ ] Conectar n8n → atlas-sales-mcp → registrar_lead
- [ ] Test E2E: lead form → crm_leads creado

### Fase 2 — Tracking
- [ ] GTM + Pixel Template instalado
- [ ] CAPI endpoint en n8n
- [ ] Event deduplication (event_id matching)
- [ ] Conversion Leads API (lead_id → conversión)

### Fase 3 — Dynamic Ads
- [ ] Product Catalog creado
- [ ] Feed hotels_master → Meta
- [ ] Campaign Dynamic Ads for Travel
- [ ] Retargeting: ViewContent → DAT → conversión

### Fase 4 — Optimización
- [ ] Custom Audiences (website visitors, lead form responders)
- [ ] Lookalike Audiences (from crm_leads cerrado_ganado)
- [ ] Insights API → War Room métricas
- [ ] Budget optimization por ROAS

---

## 11. Recursos

| Recurso | URL |
|---|---|
| SDK Codegen specs | `github.com/facebook/facebook-business-sdk-codegen` |
| Postman Collection | Incluida en este repo |
| Conversions API Builder | `github.com/facebook/capi-param-builder` |
| Conversion Leads | `github.com/facebook/Conversion-Leads-Salesforce-APEX` |
| Pixel GTM Template | `github.com/facebook/GoogleTagManager-WebTemplate-For-FacebookPixel` |
| Meta OpenAPI | `github.com/facebook/openapi` |
| Docs Marketing API | `developers.facebook.com/docs/marketing-apis` |
| Business SDK | `developers.facebook.com/docs/business-sdk/getting-started` |

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*Basado en facebook-business-sdk-codegen · 995 specs · Postman 47 endpoints*
