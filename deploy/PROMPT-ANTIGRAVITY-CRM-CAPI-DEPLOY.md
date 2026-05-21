---
title: PROMPT ANTIGRAVITY — Deploy CRM + Conversion Leads
version: 1.0
date: 2026-05-21
author: Hermes Agent
target: Antigravity (Claude Code)
---

# 🚀 DEPLOY MISSION: CRM ALIUN + Conversion Leads API

## Contexto
ALIUN TRAVEL SRL necesita su CRM propio en Supabase + la integración con Meta Conversion Leads API para optimizar campañas de Lead Ads. Todo está diseñado y documentado — solo falta ejecutar.

---

## FASE 1: Ejecutar Migration CRM v1.1 en Supabase

### Archivo SQL
`/opt/data/atlas-api-toolbox/sql/crm-v1.1-migration.sql`

### Pasos
1. Ir a Supabase Dashboard → SQL Editor
2. Copiar y ejecutar TODO el contenido del archivo SQL
3. Verificar con estas queries:

```sql
-- Verificar tablas creadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('crm_leads','crm_activities','crm_deals','crm_capi_logs');

-- Verificar columnas de crm_leads (debe incluir meta_lead_id)
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'crm_leads' ORDER BY ordinal_position;

-- Verificar RPC
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'crm_pipeline_stats';

-- Probar RPC
SELECT * FROM crm_pipeline_stats();

-- Verificar índices
SELECT indexname FROM pg_indexes WHERE tablename = 'crm_leads';
```

### Expected Output
- 4 tablas: `crm_leads`, `crm_activities`, `crm_deals`, `crm_capi_logs`
- `crm_leads` tiene columna `meta_lead_id VARCHAR(20)`
- `crm_pipeline_stats()` retorna JSON con estructura completa
- Índices creados: `idx_crm_leads_stage`, `idx_crm_leads_source`, `idx_crm_leads_meta_lead_id`, etc.
- RLS habilitado con políticas de acceso total para anon key

---

## FASE 2: Importar Workflow n8n — Conversion Leads

### Archivo
`/opt/data/atlas-api-toolbox/n8n/conversion-leads-crm-to-meta.json`

### Pasos
1. Abrir n8n (EasyPanel)
2. Ir a Workflows → Import from File
3. Subir el archivo JSON
4. Configurar las siguientes variables de entorno en n8n (Settings → Environment):

| Variable | Valor | Dónde obtenerlo |
|---|---|---|
| `META_CAPI_ENDPOINT` | `https://graph.facebook.com/v23.0/{PIXEL_ID}/events` | Events Manager → Pixel → Settings |
| `META_ACCESS_TOKEN` | Token de acceso del sistema | Events Manager → Conversions API → Settings → Generate Token |

5. Activar el workflow

### Estructura del Workflow
```
Webhook (POST /aliun-crm-stage-update)
  → Filtro (¿tiene meta_lead_id? + ¿stage != cerrado_perdido?)
    → Switch (nuevo→Initial Lead | contactado→MQL | cotizado→Sales Opp | negociando→Sales Opp | cerrado_ganado→Converted)
      → Build Payload CAPI
        → POST Meta graph.facebook.com/v23.0/{pixel_id}/events
          → Log en crm_capi_logs (Supabase)
            → Response OK
```

---

## FASE 3: Configurar Supabase Webhook para Trigger Automático

### Pasos
1. Ir a Supabase Dashboard → Database → Webhooks
2. Crear webhook:
   - **Tabla**: `crm_leads`
   - **Eventos**: `UPDATE`
   - **URL**: `https://TU-N8N-INSTANCE/webhook/aliun-crm-stage-update`
   - **Tipo**: POST
3. El webhook enviará el registro completo del lead cuando `stage` cambie

### Nota alternativa
Si Supabase no soporta webhooks en el plan, se puede usar un trigger + pg_net:

```sql
CREATE OR REPLACE FUNCTION public.notify_crm_stage_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.stage IS DISTINCT FROM NEW.stage THEN
    PERFORM net.http_post(
      url := 'https://TU-N8N-INSTANCE/webhook/aliun-crm-stage-update',
      body := json_build_object(
        'record', row_to_json(NEW),
        'old_stage', OLD.stage,
        'new_stage', NEW.stage,
        'type', 'UPDATE'
      )::text,
      headers := '{"Content-Type": "application/json"}'::jsonb
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crm_stage_change_notify
  AFTER UPDATE ON public.crm_leads
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_crm_stage_change();
```

---

## FASE 4: Probar End-to-End

### 4a. Crear lead de prueba
```sql
INSERT INTO crm_leads (full_name, phone, source, stage, meta_lead_id)
VALUES ('Test Lead', '+18095551234', 'meta_ad', 'nuevo', '1234567890123456');
```

### 4b. Avanzar stage (esto dispara el webhook)
```sql
UPDATE crm_leads SET stage = 'contactado' 
WHERE meta_lead_id = '1234567890123456';
```

### 4c. Verificar en n8n
- Ir a Executions → debe aparecer una ejecución del workflow
- Verificar que el payload se construyó correctamente

### 4d. Verificar en Events Manager
- Ir a Events Manager → Pixel → Test Events
- Debe aparecer el evento "Marketing Qualified Lead"

### 4e. Verificar auditoría
```sql
SELECT * FROM crm_capi_logs ORDER BY created_at DESC LIMIT 5;
```

---

## FASE 5: Test Event en Meta (sin lead real)

Si no hay lead real todavía, se puede enviar un test event directo:

```bash
curl -X POST "https://graph.facebook.com/v23.0/{PIXEL_ID}/events" \
  -H "Authorization: Bearer {ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "data": [{
      "event_name": "Initial Lead from Facebook",
      "event_time": 1716307200,
      "user_data": {
        "lead_id": "0"
      },
      "action_source": "system_generated",
      "custom_data": {
        "lead_event_source": "ALIUN CRM",
        "event_source": "crm"
      }
    }],
    "test_event_code": "TEST12345"
  }'
```

El `test_event_code` se obtiene en Events Manager → Test Events → Generate Code.

---

## CHECKLIST FINAL

- [ ] 4 tablas creadas en Supabase (crm_leads, crm_activities, crm_deals, crm_capi_logs)
- [ ] crm_leads tiene columna meta_lead_id
- [ ] RPC crm_pipeline_stats() funciona
- [ ] Workflow n8n importado y activo
- [ ] Variables META_CAPI_ENDPOINT y META_ACCESS_TOKEN configuradas
- [ ] Webhook Supabase→n8n configurado
- [ ] Test: INSERT + UPDATE dispara evento CAPI
- [ ] Test: Evento aparece en Meta Events Manager
- [ ] Test: crm_capi_logs tiene registro de auditoría
- [ ] Lead Ads form creado en Meta Ads Manager (Aldo)
- [ ] Campaña con Performance Goal: Conversion Leads (Aldo, después del learning phase)

---

## RECURSOS

| Archivo | Ubicación |
|---|---|
| SQL Migration v1.1 | `/opt/data/atlas-api-toolbox/sql/crm-v1.1-migration.sql` |
| Workflow n8n | `/opt/data/atlas-api-toolbox/n8n/conversion-leads-crm-to-meta.json` |
| GTI Conversion Leads | `/opt/data/atlas-api-toolbox/01-meta/conversions-api/GTI-META-CONVERSION-LEADS-CRM.md` |
| GTI WhatsApp API | `/opt/data/atlas-api-toolbox/01-meta/whatsapp-business-api-v23.0/GTI-WHATSAPP-BUSINESS-API-v23.0.md` |
| GTI Marketing API | `/opt/data/atlas-api-toolbox/01-meta/marketing-api/GTI-META-MARKETING-API.md` |

---

*Prompt generado por Hermes Agent · ATLAS-HERMES · 21 MAY 2026*
*DOCTRINA: Sin datos inventados. Sin tokens expuestos. Cash flow primero.*
