---
title: GTI · Conversion Leads — CRM Integration (Meta Events Manager)
version: 2.0.0
date: 2026-05-21
source: https://developers.facebook.com/documentation/ads-commerce/conversions-api/conversion-leads-integration
pixel_id: "[REDACTED — en Events Manager]"
business_id: "[REDACTED — en Events Manager]"
ad_account: "[REDACTED — en Events Manager]"
status: ACTIVO — Pixel creado, guía de implementación disponible
---

# GTI · Conversion Leads — CRM Integration

> **La API más importante para ALIUN**: Informa a Meta cuándo un lead se convierte en venta. Meta optimiza automáticamente campañas hacia leads que más convierten.

---

## 1. Qué hace Conversion Leads

```
LEAD FORM META → lead_id (15-17 dígitos)
     │
     ▼
CRM ALIUN (crm_leads) → stage updates
     │
     ▼
CONVERSION LEADS API → POST event por cada stage
     │
     ▼
META OPTIMIZA → Muestra ads a perfiles similares
```

**Sin esto**: Meta no sabe qué leads convierten → optimiza por volumen → leads de baja calidad.
**Con esto**: Meta sabe exactamente qué leads compran → optimiza por calidad → menos leads, más ventas.

---

## 2. Requisitos de ALIUN

| Requisito | Estado ALIUN |
|---|---|
| Usar Lead Ads (Instant Forms) | 🔲 Pendiente crear form |
| Almacenar lead_id (15-17 dígitos) | 🔲 Campo en crm_leads |
| ≥200 leads/mes | 🔲 Primeros leads |
| Subir data ≥1 vez/día | ✅ n8n puede automatizar |
| Stage final en ≤28 días | ✅ Pipeline corto |
| Tasa conversión 1-40% | ✅ Travel vertical típico |

---

## 3. Payload Specification — Parámetros Requeridos

### Estructura del Evento

```json
{
  "event_name": "nombre_del_stage_en_crm",
  "event_time": 1716307200,
  "user_data": {
    "lead_id": 1234567890123456
  },
  "action_source": "system_generated",
  "custom_data": {
    "lead_event_source": "ALIUN CRM",
    "event_source": "crm"
  }
}
```

### Parámetros Obligatorios

| Parámetro | Tipo | Valor ALIUN | Descripción |
|---|---|---|---|
| `event_name` | string | Variable — nombre del stage | **Free form**. Debe enviar TODOS los stages, incluyendo el inicial |
| `event_time` | integer | Unix timestamp del update | Máximo 7 días atrás. Debe ser posterior al lead generation time |
| `user_data` | object | Ver tabla abajo | Datos del cliente (mínimo 1 parámetro) |
| `action_source` | string | `"system_generated"` | **FIJO** para Conversion Leads |
| `lead_event_source` | string | `"ALIUN CRM"` | Nombre de la herramienta CRM (en custom_data) |
| `event_source` | string | `"crm"` | **FIJO** `"crm"` para Conversion Leads (en custom_data) |

### Customer Information Parameters (user_data)

| Parámetro | Prioridad | Uso ALIUN |
|---|---|---|
| `lead_id` ⭐ | **Highest** | Meta Lead ID (15-17 dígitos de leadgen_id webhook) |
| `click_id` | Highest | fbclid del click de ad |
| Hashed email | Highest | SHA-256, lowercase, sin espacios |
| Hashed phone | High | SHA-256, lowercase, sin espacios |
| Other (fn, ln, db, ct, st) | Medium | Opcional, mejora match rate |

**⚠️ lead_id es OBLIGATORIO si se tiene.** Si es inválido, Meta rechaza el evento.

---

## 4. Mapeo ALIUN CRM → Conversion Leads

### Stages crm_leads → event_name

| crm_leads.stage | event_name CAPI | Descripción |
|---|---|---|
| `nuevo` | `"Initial Lead from Facebook"` | Lead acaba de entrar |
| `contactado` | `"Marketing Qualified Lead"` | Vendedor contactó al lead |
| `cotizado` | `"Sales Opportunity"` | Cotización enviada |
| `negociando` | `"Sales Opportunity"` | Negociación en curso |
| `cerrado_ganado` | `"Converted"` | **CONVERSIÓN FINAL** — venta completada |
| `cerrado_perdido` | (no enviar evento) | Lead perdido, no notificar a Meta |

### ⚠️ Regla CRÍTICA
> Si un lead llega a "Converted", **TODOS los stages anteriores deben haberse enviado antes**. Meta necesita ver el journey completo para optimizar correctamente.

---

## 5. Endpoint

```
POST https://graph.facebook.com/v23.0/{pixel_id}/events
Headers:
  Authorization: Bearer {access_token}

Body (array de eventos):
[
  {
    "event_name": "Initial Lead from Facebook",
    "event_time": 1716307200,
    "user_data": {
      "lead_id": 1234567890123456
    },
    "action_source": "system_generated",
    "custom_data": {
      "lead_event_source": "ALIUN CRM",
      "event_source": "crm"
    }
  }
]
```

---

## 6. Timeline de Implementación

| Paso | Descripción | Owner | Tiempo |
|---|---|---|---|
| **1** | Conectar CRM para descargar leads | Aldo (Events Manager) | Prerequisito |
| **2** | Crear/elegir Pixel para CRM events | Aldo (Events Manager) | < 1 día |
| **3** | Implementar integración (Developer) | Hermes + n8n | < 1 día |
| **4** | Verificar data | Meta (automático) | 1-2 días |
| **5** | Configurar Sales Funnel | Aldo + Hermes | < 1 día |
| **6** | Learning Phase | Meta (automático) | 2-4 semanas |
| **Total** | | | **~3-4 semanas** |

---

## 7. Workflow n8N — Conversion Leads

```
Trigger: crm_leads UPDATE (Supabase webhook)
  │
  ├── Si stage cambió:
  │     ├── Mapear stage → event_name (tabla sección 4)
  │     ├── Construir payload CAPI
  │     │     ├── event_name = mapeo
  │     │     ├── event_time = now() Unix
  │     │     ├── user_data.lead_id = crm_leads.meta_lead_id
  │     │     ├── action_source = "system_generated"
  │     │     └── custom_data = { lead_event_source: "ALIUN CRM", event_source: "crm" }
  │     │
  │     └── POST graph.facebook.com/v23.0/{pixel_id}/events
  │
  └── Si stage NO cambió: ignorar
```

### Campo nuevo en crm_leads

```sql
ALTER TABLE crm_leads 
ADD COLUMN meta_lead_id VARCHAR(20);

COMMENT ON COLUMN crm_leads.meta_lead_id IS 
'Meta Lead ID (15-17 dígitos) del leadgen_id en webhook de Lead Ads. Requerido para Conversion Leads API.';
```

---

## 8. Verificación

### En Events Manager
1. Ir a **Events Manager → Pixel → Test Events**
2. Enviar evento de prueba desde n8n
3. Verificar que aparece con status "Received"
4. Confirmar event_name, lead_id, action_source correctos

### En Ads Manager
1. Crear campaña con **Performance Goal: Conversion Leads**
2. Seleccionar el Pixel configurado
3. Meta empezará a optimizar después del Learning Phase (2-4 semanas)

---

## 9. Recursos

| Recurso | URL |
|---|---|
| Guía oficial | `developers.facebook.com/documentation/ads-commerce/conversions-api/conversion-leads-integration` |
| Payload Spec | `.../payload-specification` |
| Find the Lead ID | `.../how-to-find-the-lead-id` |
| Developer Implementation | `.../crm-integration/3-implementing-the-crm-integration` |
| Configure Sales Funnel | `.../crm-integration/5-configure-your-sales-funnel` |
| Business Help | `facebook.com/business/help/279369167153556` |
| Events Manager (ALIUN) | `eventsmanager.facebook.com/events_manager2/` |

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*Basado en Meta Developer Docs — Conversion Leads Integration · Payload Specification · Apr 2025*
