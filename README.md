# 🔧 ATLAS API TOOLBOX

> Caja de Herramientas API — Referencia cognitiva oficial de plataformas publicitarias y de negocio para **ALIUN TRAVEL SRL**.

## Estructura

```
atlas-api-toolbox/
├── 01-meta/                           # Meta (Facebook/WhatsApp/Instagram)
│   └── whatsapp-business-api-v23.0/   # ✅ WhatsApp Business Cloud API v23.0
├── 02-google/                         # 🔲 Google (Ads, Analytics, Hotels)
├── 03-tiktok/                         # 🔲 TikTok (Ads, Business)
└── 00-templates/                      # 🔲 Plantilla GTI estándar
```

## ¿Qué es un GTI?

**Guía Técnica de Integración** — documento cognitivo que captura:
- Endpoints completos (método, path, parámetros, respuestas)
- Schemas clave con ejemplos JSON
- Diagrama de integración con el stack ALIUN
- Checklist de implementación por fases
- Comparativas con alternativas
- Modelo de precios y limitaciones

## GTIs Disponibles

| # | Plataforma | GTI | Endpoints | Schemas | Status |
|---|---|---|---|---|---|
| 1 | Meta — WhatsApp Business API | [v23.0](./01-meta/whatsapp-business-api-v23.0/GTI-WHATSAPP-BUSINESS-API-v23.0.md) | 113 | 369 | ✅ Completo |
| 2 | Meta — Ads API | — | — | — | 🔲 Pendiente |
| 3 | Google — Ads API | — | — | — | 🔲 Pendiente |
| 4 | Google — Hotels API | — | — | — | 🔲 Pendiente |
| 5 | TikTok — Ads API | — | — | — | 🔲 Pendiente |

## Convención de Nombres

- Carpeta: `{NN}-{plataforma}/{servicio}-api-v{version}/`
- Documento: `GTI-{SERVICIO}-API-v{VERSION}.md`
- Spec original: `spec.yaml` o `spec.json` (sin modificar)

## Fuentes de Tráfico ALIUN

| Fuente | Plataforma | Funnel | API Requerida |
|---|---|---|---|
| Meta Ads | Facebook/Instagram | Ad → Website → Widget → MCP | Meta Marketing API + WhatsApp API |
| Google Ads | Search/Display | Search → Website → Widget → MCP | Google Ads API + Hotels API |
| TikTok Ads | TikTok | Video → Link → Website → MCP | TikTok Marketing API |

## Acceso

- **Repo:** `aliuntravelsrl-hash/atlas-api-toolbox` (privado)
- **Uso:** Referencia para todos los agentes ATLAS (Hermes, Antigravity, OpenClaw)
- **Actualización:** Cada GTI se actualiza cuando la plataforma libera nueva versión de API

---

*Mantenido por Hermes Agent · ATLAS-HERMES · 2026*
