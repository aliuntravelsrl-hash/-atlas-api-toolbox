-- ═══════════════════════════════════════════════════════════════════
-- ARIADNE DATA — Analytics RPCs v1.0
-- Crea: funnel_conversion, funnel_velocity, revenue_by_period,
--        revenue_by_hotel, margin_analysis, stale_leads, segment_summary
-- Proyecto: oyihiyivdhfxpyiwnmqk
-- Fecha: 2026-06-07
-- Autor: Hermes Ops (Ariadne Data = 2do sombrero)
-- Ejecutar en: Supabase Dashboard → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════

-- ─── RPC 1: funnel_conversion ─────────────────────────────────
-- Tasa de conversión por etapa del embudo
-- Ariadne skill: funnel_conversion, funnel_dropoff
CREATE OR REPLACE FUNCTION public.funnel_conversion(
  p_from_date date DEFAULT CURRENT_DATE - 30,
  p_to_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'period', jsonb_build_object('from', p_from_date, 'to', p_to_date),
    'stages', jsonb_build_object(
      'nuevo', COUNT(*) FILTER (WHERE stage = 'nuevo'),
      'contactado', COUNT(*) FILTER (WHERE stage = 'contactado'),
      'cotizado', COUNT(*) FILTER (WHERE stage = 'cotizado'),
      'negociando', COUNT(*) FILTER (WHERE stage = 'negociando'),
      'confirmada', COUNT(*) FILTER (WHERE stage = 'confirmada'),
      'cerrado_ganado', COUNT(*) FILTER (WHERE stage = 'cerrado_ganado'),
      'cerrado_perdido', COUNT(*) FILTER (WHERE stage = 'cerrado_perdido'),
      'perdido', COUNT(*) FILTER (WHERE stage = 'perdido')
    ),
    'total', COUNT(*),
    'conversion_rates', jsonb_build_object(
      'nuevo_to_cotizado_pct',
        ROUND((COUNT(*) FILTER (WHERE stage IN ('cotizado','negociando','confirmada','cerrado_ganado')))::numeric
          / NULLIF(COUNT(*)::numeric, 0) * 100, 1),
      'cotizado_to_confirmada_pct',
        ROUND((COUNT(*) FILTER (WHERE stage IN ('confirmada','cerrado_ganado')))::numeric
          / NULLIF((COUNT(*) FILTER (WHERE stage IN ('cotizado','negociando','confirmada','cerrado_ganado')))::numeric, 0) * 100, 1),
      'overall_conversion_pct',
        ROUND((COUNT(*) FILTER (WHERE stage IN ('confirmada','cerrado_ganado')))::numeric
          / NULLIF(COUNT(*)::numeric, 0) * 100, 1)
    ),
    'biggest_stage', (
      SELECT stage FROM public.crm_leads
      WHERE created_at BETWEEN p_from_date AND p_to_date + interval '1 day'
      GROUP BY stage ORDER BY COUNT(*) DESC LIMIT 1
    )
  )
  FROM public.crm_leads
  WHERE created_at BETWEEN p_from_date AND p_to_date + interval '1 day';
$$ LANGUAGE sql STABLE;


-- ─── RPC 2: funnel_velocity ───────────────────────────────────
-- Tiempo promedio entre etapas del pipeline
-- Ariadne skill: funnel_velocity
CREATE OR REPLACE FUNCTION public.funnel_velocity(
  p_from_date date DEFAULT CURRENT_DATE - 30,
  p_to_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb AS $$
  WITH transitions AS (
    SELECT
      a1.lead_id,
      a1.content AS from_stage,
      a2.content AS to_stage,
      EXTRACT(EPOCH FROM (a2.created_at - a1.created_at)) / 3600 AS hours_between
    FROM public.crm_activities a1
    JOIN public.crm_activities a2
      ON a1.lead_id = a2.lead_id
      AND a2.created_at > a1.created_at
      AND a2.type = 'pipeline_change'
    WHERE a1.type = 'pipeline_change'
      AND a1.created_at BETWEEN p_from_date AND p_to_date + interval '1 day'
  ),
  stage_times AS (
    SELECT
      from_stage,
      to_stage,
      COUNT(*) AS transitions,
      ROUND(AVG(hours_between)::numeric, 1) AS avg_hours,
      ROUND(MIN(hours_between)::numeric, 1) AS min_hours,
      ROUND(MAX(hours_between)::numeric, 1) AS max_hours
    FROM transitions
    GROUP BY from_stage, to_stage
  )
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'from', from_stage,
      'to', to_stage,
      'transitions', transitions,
      'avg_hours', avg_hours,
      'min_hours', min_hours,
      'max_hours', max_hours
    )
    ORDER BY from_stage, to_stage
  ), '[]'::jsonb)
  FROM stage_times;
$$ LANGUAGE sql STABLE;


-- ─── RPC 3: revenue_by_period ─────────────────────────────────
-- Ingresos por rango de fechas con desglose por status
-- Ariadne skill: revenue_by_period
CREATE OR REPLACE FUNCTION public.revenue_by_period(
  p_from_date date DEFAULT CURRENT_DATE - 30,
  p_to_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'period', jsonb_build_object('from', p_from_date, 'to', p_to_date),
    'summary', jsonb_build_object(
      'total_revenue', COALESCE(SUM(d.total_usd), 0),
      'total_deals', COUNT(*),
      'confirmed_revenue', COALESCE(SUM(d.total_usd) FILTER (WHERE d.status = 'confirmada'), 0),
      'pending_revenue', COALESCE(SUM(d.total_usd) FILTER (WHERE d.status IN ('pendiente','aprobada','depositado')), 0),
      'lost_revenue', COALESCE(SUM(d.total_usd) FILTER (WHERE d.status = 'perdida'), 0),
      'avg_deal_size', COALESCE(ROUND(AVG(d.total_usd), 2), 0)
    ),
    'by_status', (
      SELECT jsonb_object_agg(status, jsonb_build_object('count', cnt, 'revenue', rev))
      FROM (
        SELECT d.status, COUNT(*) AS cnt, COALESCE(SUM(d.total_usd), 0) AS rev
        FROM public.crm_deals d
        WHERE d.created_at BETWEEN p_from_date AND p_to_date + interval '1 day'
        GROUP BY d.status
      ) s
    )
  )
  FROM public.crm_deals d
  WHERE d.created_at BETWEEN p_from_date AND p_to_date + interval '1 day';
$$ LANGUAGE sql STABLE;


-- ─── RPC 4: revenue_by_hotel ──────────────────────────────────
-- Ingresos por hotel/destino con ranking
-- Ariadne skill: revenue_by_hotel
CREATE OR REPLACE FUNCTION public.revenue_by_hotel(
  p_from_date date DEFAULT CURRENT_DATE - 30,
  p_to_date date DEFAULT CURRENT_DATE,
  p_limit integer DEFAULT 10
)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'period', jsonb_build_object('from', p_from_date, 'to', p_to_date),
    'hotels', COALESCE(jsonb_agg(
      jsonb_build_object(
        'hotel_slug', stats.hotel_slug,
        'hotel_name', COALESCE(h.name, stats.hotel_slug),
        'hotel_zone', h.zone,
        'deal_count', stats.deal_count,
        'total_revenue', stats.total_revenue,
        'confirmed_revenue', stats.confirmed_revenue,
        'avg_deal', stats.avg_deal
      )
      ORDER BY stats.total_revenue DESC NULLS LAST
    ), '[]'::jsonb)
  )
  FROM (
    SELECT
      d.hotel_slug,
      COUNT(*) AS deal_count,
      COALESCE(SUM(d.total_usd), 0) AS total_revenue,
      COALESCE(SUM(d.total_usd) FILTER (WHERE d.status = 'confirmada'), 0) AS confirmed_revenue,
      COALESCE(ROUND(AVG(d.total_usd), 2), 0) AS avg_deal
    FROM public.crm_deals d
    WHERE d.created_at BETWEEN p_from_date AND p_to_date + interval '1 day'
    GROUP BY d.hotel_slug
    ORDER BY total_revenue DESC NULLS LAST
    LIMIT p_limit
  ) stats
  LEFT JOIN public.hotels_master h ON h.slug = stats.hotel_slug;
$$ LANGUAGE sql STABLE;


-- ─── RPC 5: margin_analysis ───────────────────────────────────
-- Análisis de márgenes brutos/netos
-- Ariadne skill: margin_analysis
CREATE OR REPLACE FUNCTION public.margin_analysis(
  p_from_date date DEFAULT CURRENT_DATE - 30,
  p_to_date date DEFAULT CURRENT_DATE
)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'period', jsonb_build_object('from', p_from_date, 'to', p_to_date),
    'summary', jsonb_build_object(
      'total_revenue', COALESCE(SUM(d.total_usd), 0),
      'avg_margin_pct', COALESCE(ROUND(AVG(d.margin_pct), 1), 0),
      'total_margin_usd', COALESCE(ROUND(SUM(d.total_usd * COALESCE(d.margin_pct, 10) / 100), 2), 0),
      'deals_with_margin', COUNT(*) FILTER (WHERE d.margin_pct IS NOT NULL),
      'deals_without_margin', COUNT(*) FILTER (WHERE d.margin_pct IS NULL)
    ),
    'by_hotel', COALESCE(jsonb_agg(
      jsonb_build_object(
        'hotel_slug', d.hotel_slug,
        'avg_margin_pct', COALESCE(ROUND(AVG(d.margin_pct), 1), 0),
        'total_margin_usd', COALESCE(ROUND(SUM(d.total_usd * COALESCE(d.margin_pct, 10) / 100), 2), 0),
        'deal_count', COUNT(*)
      )
      ORDER BY AVG(d.margin_pct) DESC NULLS LAST
    ), '[]'::jsonb)
  )
  FROM public.crm_deals d
  WHERE d.created_at BETWEEN p_from_date AND p_to_date + interval '1 day';
$$ LANGUAGE sql STABLE;


-- ─── RPC 6: stale_leads ──────────────────────────────────────
-- Leads sin actividad > N horas (alerta operativa)
-- Ariadne skill: stale_lead_alert
CREATE OR REPLACE FUNCTION public.stale_leads(
  p_hours integer DEFAULT 48
)
RETURNS jsonb AS $$
  WITH stale AS (
    SELECT
      l.id, l.full_name, l.phone, l.stage, l.source,
      l.hotel_interest, l.updated_at,
      ROUND(EXTRACT(EPOCH FROM (now() - l.updated_at)) / 3600, 0)::int AS hours_stale
    FROM public.crm_leads l
    WHERE l.updated_at < now() - (p_hours || ' hours')::interval
      AND l.stage NOT IN ('cerrado_ganado', 'cerrado_perdido', 'perdido', 'confirmada')
  )
  SELECT jsonb_build_object(
    'threshold_hours', p_hours,
    'total_stale', (SELECT COUNT(*) FROM stale),
    'by_stage', (
      SELECT jsonb_object_agg(stage, cnt) FROM (
        SELECT stage, COUNT(*) AS cnt FROM stale GROUP BY stage
      ) s
    ),
    'by_source', (
      SELECT jsonb_object_agg(source, cnt) FROM (
        SELECT source, COUNT(*) AS cnt FROM stale GROUP BY source
      ) s2
    ),
    'leads', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'id', id, 'name', full_name, 'phone', phone,
          'stage', stage, 'source', source,
          'hotel_interest', hotel_interest,
          'last_activity', updated_at, 'hours_stale', hours_stale
        )
        ORDER BY updated_at ASC LIMIT 20
      ), '[]'::jsonb)
      FROM stale
    )
  );
$$ LANGUAGE sql STABLE;


-- ─── RPC 7: segment_summary ──────────────────────────────────
-- Distribución de leads por segmento (source + hotel_interest)
-- Ariadne skill: segment_summary
CREATE OR REPLACE FUNCTION public.segment_summary()
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'by_source', (
      SELECT jsonb_agg(jsonb_build_object(
        'source', source, 'count', cnt, 'pct', ROUND(pct, 1)
      ) ORDER BY cnt DESC)
      FROM (
        SELECT source, COUNT(*) AS cnt,
          (COUNT(*)::numeric / NULLIF((SELECT COUNT(*) FROM public.crm_leads)::numeric, 0)) * 100 AS pct
        FROM public.crm_leads GROUP BY source
      ) s
    ),
    'by_hotel_interest', (
      SELECT jsonb_agg(jsonb_build_object(
        'hotel', COALESCE(hotel_interest, 'sin_destino'), 'count', cnt
      ) ORDER BY cnt DESC LIMIT 15)
      FROM (
        SELECT hotel_interest, COUNT(*) AS cnt
        FROM public.crm_leads
        GROUP BY hotel_interest
      ) h
    ),
    'by_stage', (
      SELECT jsonb_agg(jsonb_build_object(
        'stage', stage, 'count', cnt
      ) ORDER BY cnt DESC)
      FROM (
        SELECT stage, COUNT(*) AS cnt
        FROM public.crm_leads GROUP BY stage
      ) st
    ),
    'total_leads', (SELECT COUNT(*) FROM public.crm_leads),
    'total_deals', (SELECT COUNT(*) FROM public.crm_deals),
    'pipeline_value', (
      SELECT COALESCE(SUM(total_usd), 0) FROM public.crm_deals
      WHERE status IN ('pendiente','aprobada','depositado')
    )
  );
$$ LANGUAGE sql STABLE;


-- ─── SCHEMA CACHE RELOAD ──────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ═══════════════════════════════════════════════════════════════════
-- FIN ARIADNE ANALYTICS v1.0 — 7 RPCs para Data & Analytics
-- ═══════════════════════════════════════════════════════════════════
