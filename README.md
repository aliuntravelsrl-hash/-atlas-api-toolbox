# 🔧 ATLAS API TOOLBOX

> Caja de Herramientas API — Referencia cognitiva oficial de plataformas publicitarias y de negocio para **ALIUN TRAVEL SRL**.
> Cada GTI (Guía Técnica de Integración) es un documento autocontenido con endpoints, schemas, ejemplos, diagramas ALIUN y checklist.

---

## 📊 Inventario de GTIs

### 01 — META

| GTI | Especs | Postman | Status | Prioridad ALIUN |
|---|---|---|---|---|
| [WhatsApp Business API v23.0](01-meta/whatsapp-business-api-v23.0/GTI-WHATSAPP-BUSINESS-API-v23.0.md) | 113 endpoints, 369 schemas | — | ✅ Completo | 🔴 Crítica |
| [Marketing API (MAPI)](01-meta/marketing-api/GTI-META-MARKETING-API.md) | 995 JSON specs, 47 Postman | 89KB, 10 folders | ✅ Completo | 🔴 Crítica |
| [Conversions API (CAPI) + Pixel](01-meta/conversions-api/GTI-META-CONVERSIONS-API.md) | CAPI SDK + Param Builder | — | ✅ Completo | 🟡 Alta |
| ~~Instagram Graph API~~ | — | — | 🔲 Pendiente | 🟡 Media |
| ~~Messenger API~~ | — | — | 🔲 Pendiente | 🟢 Baja |

### 02 — GOOGLE

| GTI | Specs | MCP Server | Status | Prioridad ALIUN |
|---|---|---|---|---|
| [Google Ads API](02-google/google-ads-api/GTI-GOOGLE-ADS-API.md) | Discovery Document + GAQL | ✅ Oficial (530⭐) | ✅ Completo | 🔴 Crítica |
| ~~Google Analytics API~~ | — | — | 🔲 Pendiente | 🟡 Media |
| ~~Google Hotel Ads~~ | — | — | 🔲 Pendiente | 🟡 Alta |

### 03 — TIKTOK

| GTI | Specs | MCP Server | Status | Prioridad ALIUN |
|---|---|---|---|---|
| [TikTok Marketing API](03-tiktok/tiktok-marketing-api/GTI-TIKTOK-MARKETING-API.md) | Portal docs (no OpenAPI) | — | 🟡 Placeholder | 🟢 Baja |

---

## 🏗 Estructura del Repo

```
atlas-api-toolbox/
├── README.md                              ← ESTE ARCHIVO
├── sql/                                   
│   └── crm-v1.0-migration.sql             ← CRM ALIUN (3 tablas + 1 RPC)
│
├── 01-meta/
│   ├── whatsapp-business-api-v23.0/
│   │   ├── GTI-WHATSAPP-BUSINESS-API-v23.0.md   ← 113 endpoints, 369 schemas
│   │   └── spec.yaml                             ← OpenAPI original (1MB)
│   ├── marketing-api/
│   │   ├── GTI-META-MARKETING-API.md             ← 995 specs, Postman, flows
│   │   ├── MAPI-Postman-Collection.json          ← 47 endpoints listos
│   │   ├── SDKCodegen.json                        ← SDK config
│   │   └── specs/                                 ← 12 JSON specs clave
│   ├── conversions-api/
│   │   └── GTI-META-CONVERSIONS-API.md           ← CAPI + Pixel + Conversion Leads
│   ├── pixel-gtm/
│   │   └── README-Pixel-GTM.md                   ← GTM Template reference
│   └── conversion-leads/
│       └── README-Conversion-Leads.md             ← Salesforce APEX reference
│
├── 02-google/
│   ├── google-ads-api/
│   │   └── GTI-GOOGLE-ADS-API.md                 ← API + MCP Server oficial
│   └── google-ads-mcp/
│       ├── README.md                              ← Setup MCP Server
│       └── pyproject.toml                         ← Dependencies
│
└── 03-tiktok/
    └── tiktok-marketing-api/
        ├── GTI-TIKTOK-MARKETING-API.md            ← Placeholder (no spec oficial)
        └── README-REFERENCE.md                     ← Portal docs reference
```

---

## 🔗 Fuentes Oficiales

| Plataforma | Repo Oficial | Specs |
|---|---|---|
| Meta OpenAPI | `facebook/openapi` | 1 YAML (WhatsApp) |
| Meta SDK Codegen | `facebook/facebook-business-sdk-codegen` | 995 JSON specs |
| Meta CAPI Builder | `facebook/capi-param-builder` | SDK multi-lenguaje |
| Meta Pixel GTM | `facebook/GoogleTagManager-WebTemplate-For-FacebookPixel` | Template |
| Meta Conv. Leads | `facebook/Conversion-Leads-Salesforce-APEX` | Reference |
| Google Ads MCP | `googleads/google-ads-mcp` | MCP Server (530⭐) |
| Google Ads Asst. | `googleads/google-ads-api-developer-assistant` | LLM Assistant |
| TikTok Business | `business-api.tiktok.com/portal` | Portal docs only |

---

## 📋 Reglas

1. **Solo fuentes oficiales** — No specs inventados ni de terceros
2. **Un GTI por API** — Formato estándar: info, arquitectura, endpoints, flujo ALIUN, checklist
3. **Diagrams específicos** — Cada GTI incluye flujo ALIUN: Ad → Lead → CRM → Venta
4. **Sin credenciales** — NUNCA keys, tokens ni secrets en este repo
5. **Actualización** — Cuando Meta/Google/TikTok publiquen nuevas specs, actualizar aquí

---

*Última actualización: 21 MAY 2026 · Hermes Agent · ATLAS-HERMES*
