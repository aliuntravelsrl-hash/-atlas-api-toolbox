---
title: Arquitectura BD ALIUN — Patrón Madre→Hijas
version: 1.0
date: 2026-05-21
principio: Dato actualizado en página madre, hijas = referencias evolutivas
---

# 🏛️ Arquitectura BD ALIUN — Patrón Madre→Hijas

## Principio Fundamental

> **1 página madre + N páginas hijas**
> - **Madre**: Dato ACTUALIZADO — el estado vivo del registro, siempre sobrescrito
> - **Hijas**: Referencias EVOLUTIVAS — historial append-only, nunca se modifica

```
┌─────────────────────────────────┐
│         PÁGINA MADRE           │
│  Estado ACTUAL del registro     │
│  Se ACTUALIZA (UPDATE)          │
│  Siempre tiene el último valor  │
├─────────────────────────────────┤
│  crm_leads:                     │
│  full_name = "María García"    │
│  stage = "cotizado" ← ACTUAL   │
│  phone = "+18095551234"        │
│  meta_lead_id = "12345..."     │
└──────────┬──────────────────────┘
           │ FK (lead_id)
           ▼
┌──────────────────────────────────────────────────┐
│            PÁGINAS HIJAS (evolutivas)             │
│  Solo APPEND (INSERT) — NUNCA UPDATE ni DELETE   │
├──────────┬───────────┬────────────┬───────────────┤
│activities│  deals    │ capi_logs  │  cotizaciones │
├──────────┼───────────┼────────────┼───────────────┤
│nuevo     │ pendiente │ Initial... │ COT-2026-001  │
│contactado│ aprobada  │ MQL sent   │ COT-2026-002  │
│cotizado  │           │ Sales Opp  │               │
│          │           │            │               │
└──────────┴───────────┴────────────┴───────────────┘
  timeline completo    deals      auditoría Meta    PDFs generados
  del journey          intentos   eventos enviados  landing_url
```

---

## Mapa Completo: Madres e Hijas en Supabase

### MADRE 1: crm_leads (el lead vivo)

| Campo | Tipo | Rol |
|---|---|---|
| id | uuid | PK |
| full_name | text | ACTUALIZADO |
| phone | text | ACTUALIZADO |
| email | text | ACTUALIZADO |
| source | text | ACTUALIZADO (de dónde vino) |
| hotel_interest | text | ACTUALIZADO |
| check_in / check_out | date | ACTUALIZADO |
| stage | text | **ACTUALIZADO** ← el campo más importante |
| assigned_to | text | ACTUALIZADO |
| chatwoot_id | text | ACTUALIZADO |
| meta_lead_id | VARCHAR(20) | ACTUALIZADO |
| created_at | timestamptz | Inmutable |
| updated_at | timestamptz | Auto-update |

**HIJAS de crm_leads:**

| Tabla Hija | Qué registra | Trigger de append |
|---|---|---|
| `crm_activities` | Cada acción: nota, llamada, pipeline_change, cotización | INSERT cuando algo pasa |
| `crm_deals` | Cada intento de deal: cotización enviada, depositado, confirmada | INSERT por cotización |
| `crm_capi_logs` | Cada evento enviado a Meta Conversion Leads | INSERT por POST a Meta |
| `cotizaciones` (existente) | Cada PDF generado + landing_url | INSERT por MCP tool |

### MADRE 2: hotels (catálogo vivo)

| Campo | Tipo | Rol |
|---|---|---|
| slug | text | PK inmutable |
| name | text | ACTUALIZADO |
| destination | text | ACTUALIZADO |
| star_rating | int | ACTUALIZADO |
| base_price_usd | numeric | ACTUALIZADO |
| amenities | jsonb | ACTUALIZADO |
| active | bool | ACTUALIZADO |

**HIJAS de hotels:**
- `hotel_rates` (temporadas, precios por fecha) — evolutiva
- `hotel_images` (galería) — evolutiva
- `hotel_reviews` (reviews scraping) — evolutiva

### MADRE 3: bookings (reserva confirmada)

| Campo | Tipo | Rol |
|---|---|---|
| id | text | PK (booking_id) |
| lead_id | uuid | FK → crm_leads |
| hotel_slug | text | FK → hotels |
| status | text | ACTUALIZADO |
| check_in / check_out | date | ACTUALIZADO |
| total_usd | numeric | ACTUALIZADO |
| deposit_paid | bool | ACTUALIZADO |
| landing_url | text | Inmutable (PDF generado) |

**HIJAS de bookings:**
- `booking_payments` (cada pago recibido) — evolutiva
- `booking_communications` (emails/WA enviados) — evolutiva

---

## Reglas de Oro del Patrón

### ✅ En la MADRE (UPDATE)
1. **Siempre sobrescribir** — el registro madre tiene el ÚLTIMO estado
2. **No borrar** — solo marcar como inactivo/cerrado
3. **updated_at automático** — trigger siempre activo
4. **Consultas rápidas** — la madre tiene todo lo que necesitas en 1 query

### ✅ En las HIJAS (INSERT ONLY)
1. **Solo INSERT** — nunca UPDATE, nunca DELETE
2. **Append-only** — cada nueva acción es un registro nuevo
3. **FK a madre** — siempre referencian el id de la madre
4. **Timeline reconstruible** — leyendo solo las hijas, puedes reconstruir todo el journey

### ❌ NUNCA
- Mover un registro de hija a madre
- Borrar una hija (rompe el timeline)
- Hacer UPDATE en una hija (rompe la auditabilidad)
- Duplicar en madre datos que ya están en hijas (redundancia)

---

## Queries Canónicas

### Ver lead actual (MADRE — 1 query)
```sql
SELECT * FROM crm_leads WHERE id = $1;
```

### Ver journey completo (HIJAS — timeline)
```sql
-- Todas las actividades del lead, en orden cronológico
SELECT type, content, created_at 
FROM crm_activities 
WHERE lead_id = $1 
ORDER BY created_at ASC;

-- Todos los deals intentados
SELECT hotel_slug, status, total_usd, created_at 
FROM crm_deals 
WHERE lead_id = $1 
ORDER BY created_at ASC;

-- Todos los eventos Meta enviados
SELECT event_name, stage_crm, status, event_time 
FROM crm_capi_logs 
WHERE lead_id = $1 
ORDER BY event_time ASC;
```

### Reconstruir journey completo (JOIN hijas)
```sql
SELECT 'activity' AS source, type AS action, content AS detail, created_at
FROM crm_activities WHERE lead_id = $1
UNION ALL
SELECT 'deal' AS source, hotel_slug AS action, status AS detail, created_at
FROM crm_deals WHERE lead_id = $1
UNION ALL
SELECT 'capi' AS source, event_name AS action, stage_crm AS detail, event_time AS created_at
FROM crm_capi_logs WHERE lead_id = $1
ORDER BY created_at ASC;
```

### Estadísticas pipeline (MADRE aggregada)
```sql
SELECT * FROM crm_pipeline_stats();
```

---

## Aplicación en Notion

### Estructura Notion → Madre e Hijas

```
📋 BD ALIUN CRM (Notion)
├── 📄 [Madre] Lead: María García
│   ├── Stage: cotizado (ACTUALIZADO)
│   ├── Phone: +1809... (ACTUALIZADO)
│   ├── Meta Lead ID: 12345... (ACTUALIZADO)
│   │
│   ├── 📎 [Hija] Actividad: Contactado por WA — 21 MAY 10:30
│   ├── 📎 [Hija] Actividad: Cotización enviada — 21 MAY 11:00
│   ├── 📎 [Hija] Deal: Hotel X $1,200 — pendiente
│   ├── 📎 [Hija] CAPI Log: MQL sent to Meta — 21 MAY 10:31
│   └── 📎 [Hija] CAPI Log: Sales Opp sent — 21 MAY 11:01
```

### Propiedades Notion (Madre)
- `Stage` → Select (nuevo, contactado, cotizado, negociando, cerrado_ganado, cerrado_perdido)
- `Source` → Select (widget, whatsapp, meta_ad, google_ad)
- `Meta Lead ID` → Text
- `Assigned To` → Person
- `Hotel Interest` → Select
- `Last Activity` → Formula (MAX de hijas created_at)

### Hijas = Sub-items o Related Database
- Cada actividad/deal/capi_log es un item en su propia BD
- Relación: `lead_id` → Linked Database Property

---

## Aplicación en Horizons

### Vista Pipeline (Kanban)
- Columnas = stages (nuevo → contactado → cotizado → negociando → cerrado)
- Tarjeta = **MADRE** (crm_leads con estado actual)
- Click en tarjeta → Timeline lateral con **HIJAS** (activities + deals + capi_logs)

### Vista Lead Detail
```
┌──────────────────────────────────────┐
│ 🟡 María García — COTIZADO          │ ← MADRE (dato actual)
│ 📱 +18095551234 | 📧 maria@...      │
│ 🏨 Hotel X | 🗓 15-20 Jun           │
│ 🆔 Meta: 1234567890123456            │
├──────────────────────────────────────┤
│ 📜 TIMELINE (hijas evolutivas)       │
│                                      │
│ ● 10:30 — ✅ Nuevo (Initial Lead)   │ ← capi_log
│ ● 10:31 — 📞 Contactado por WA     │ ← activity + capi_log
│ ● 11:00 — 📋 Cotización $1,200     │ ← activity + deal
│ ● 11:01 — 📤 Sales Opp → Meta      │ ← capi_log
│ ● 11:15 — 💬 "Gracias, reviso"      │ ← activity (WA msg)
│                                      │
│ [+ Agregar nota] [+ Enviar WA]      │
└──────────────────────────────────────┘
```

---

## Checklist de Implementación

- [x] Patrón definido: Madre (UPDATE) + Hijas (INSERT only)
- [x] CRM migration v1.1 con 4 tablas (1 madre + 3 hijas)
- [x] Trigger updated_at automático en madre
- [x] FK lead_id en todas las hijas
- [x] crm_capi_logs como hija evolutiva de auditoría Meta
- [ ] Ejecutar migration en Supabase (Antigravity)
- [ ] Crear páginas Notion con estructura madre→hijas
- [ ] Horizons: Vista Kanban (madres) + Timeline (hijas)
- [ ] Supabase webhook para auto-append en hijas cuando madre se actualiza

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*Inspirado en Meta Events Manager CRM Implementation Guide*
*Patrón: Event Sourcing aplicado a BD relacional — madre = projection, hijas = event log*
