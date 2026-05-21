-- ═══════════════════════════════════════════════════════════════════
-- CRM ALIUN — Migration v1.0
-- Crea: crm_leads, crm_activities, crm_deals + crm_pipeline_stats()
-- Proyecto: oyihiyivdhfxpyiwnmqk
-- Fecha: 2026-05-21
-- ═══════════════════════════════════════════════════════════════════

-- ─── TABLA 1: crm_leads ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crm_leads (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name       text NOT NULL,
  phone           text,
  email           text,
  source          text NOT NULL DEFAULT 'widget'
                  CHECK (source IN ('widget','whatsapp','meta_ad','google_ad','tiktok_ad','referral','manual')),
  hotel_interest  text,                     -- slug del hotel
  check_in        date,
  check_out       date,
  adults          integer DEFAULT 2,
  children        integer DEFAULT 0,
  budget_range    text,
  message         text,                     -- primer mensaje del lead
  stage           text NOT NULL DEFAULT 'nuevo'
                  CHECK (stage IN ('nuevo','contactado','cotizado','negociando','cerrado_ganado','cerrado_perdido')),
  assigned_to     text DEFAULT 'director',  -- agente asignado
  chatwoot_id     text,                     -- link a conversación Chatwoot
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Índices para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_crm_leads_stage ON public.crm_leads(stage);
CREATE INDEX IF NOT EXISTS idx_crm_leads_source ON public.crm_leads(source);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned ON public.crm_leads(assigned_to);
CREATE INDEX IF NOT EXISTS idx_crm_leads_created ON public.crm_leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crm_leads_phone ON public.crm_leads(phone);

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crm_leads_updated_at
  BEFORE UPDATE ON public.crm_leads
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ─── TABLA 2: crm_activities ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crm_activities (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         uuid NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
  type            text NOT NULL
                  CHECK (type IN ('nota','llamada','whatsapp','cotizacion','email','sistema','pipeline_change')),
  content         text NOT NULL,
  cotizacion_id   text,                     -- referencia a id_cotizacion
  created_by      text NOT NULL DEFAULT 'sistema'
                  CHECK (created_by IN ('director','hermes','atlas-tech','openclaw','antigravity','sistema')),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_crm_activities_lead ON public.crm_activities(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_activities_created ON public.crm_activities(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_crm_activities_type ON public.crm_activities(type);

-- ─── TABLA 3: crm_deals ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crm_deals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id         uuid NOT NULL REFERENCES public.crm_leads(id) ON DELETE CASCADE,
  hotel_slug      text NOT NULL,
  check_in        date NOT NULL,
  check_out       date NOT NULL,
  adults          integer NOT NULL DEFAULT 2,
  children        integer NOT NULL DEFAULT 0,
  total_usd      numeric(10,2),
  margin_pct      numeric(5,2),
  landing_url     text,
  cotizacion_id   text,
  status          text NOT NULL DEFAULT 'pendiente'
                  CHECK (status IN ('pendiente','aprobada','depositado','confirmada','perdida')),
  deposit_amount  numeric(10,2),
  deposit_date    timestamptz,
  booking_id      text,                     -- FK a bookings cuando se confirma
  lost_reason     text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_crm_deals_lead ON public.crm_deals(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_deals_status ON public.crm_deals(status);
CREATE INDEX IF NOT EXISTS idx_crm_deals_hotel ON public.crm_deals(hotel_slug);
CREATE INDEX IF NOT EXISTS idx_crm_deals_created ON public.crm_deals(created_at DESC);

CREATE TRIGGER trg_crm_deals_updated_at
  BEFORE UPDATE ON public.crm_deals
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- ─── FUNCIÓN RPC: crm_pipeline_stats() ─────────────────────────
CREATE OR REPLACE FUNCTION public.crm_pipeline_stats()
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'leads_by_stage', (
      SELECT jsonb_object_agg(stage, cnt)
      FROM (
        SELECT stage, count(*)::int AS cnt
        FROM public.crm_leads
        GROUP BY stage
      ) s
    ),
    'leads_by_source', (
      SELECT jsonb_object_agg(source, cnt)
      FROM (
        SELECT source, count(*)::int AS cnt
        FROM public.crm_leads
        GROUP BY source
      ) s
    ),
    'deals_by_status', (
      SELECT jsonb_object_agg(status, cnt)
      FROM (
        SELECT status, count(*)::int AS cnt
        FROM public.crm_deals
        GROUP BY status
      ) s
    ),
    'deals_revenue_pending', (
      SELECT coalesce(sum(total_usd), 0)::numeric
      FROM public.crm_deals
      WHERE status IN ('pendiente','aprobada','depositado')
    ),
    'deals_revenue_confirmed', (
      SELECT coalesce(sum(total_usd), 0)::numeric
      FROM public.crm_deals
      WHERE status = 'confirmada'
    ),
    'total_leads', (SELECT count(*)::int FROM public.crm_leads),
    'total_deals', (SELECT count(*)::int FROM public.crm_deals),
    'avg_days_nuevo_to_cotizado', (
      SELECT coalesce(round(avg(extract(epoch from (a2.created_at - a1.created_at))/86400), 1), 0)::numeric
      FROM public.crm_activities a1
      JOIN public.crm_activities a2 ON a1.lead_id = a2.lead_id
      WHERE a1.type = 'pipeline_change' AND a1.content = 'nuevo'
        AND a2.type = 'pipeline_change' AND a2.content = 'cotizado'
        AND a2.created_at > a1.created_at
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ─── RLS (Row Level Security) ──────────────────────────────────
-- Por ahora deshabilitado para acceso desde MCP server con anon key
-- Cuando se implemente auth en Horizons, activar RLS

ALTER TABLE public.crm_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crm_deals ENABLE ROW LEVEL SECURITY;

-- Políticas de acceso total para anon key (MCP server)
CREATE POLICY "crm_leads_anon_full" ON public.crm_leads
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "crm_activities_anon_full" ON public.crm_activities
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "crm_deals_anon_full" ON public.crm_deals
  FOR ALL USING (true) WITH CHECK (true);

-- ─── Recargar schema cache ─────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ═══════════════════════════════════════════════════════════════════
-- FIN MIGRATION v1.0
-- ═══════════════════════════════════════════════════════════════════
