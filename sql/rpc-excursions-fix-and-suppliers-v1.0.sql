-- ═══════════════════════════════════════════════════════════════════
-- ATLAS API TOOLBOX — SQL MIGRATION: EXCURSIONS FIX & SUPPLIERS v1.0
-- Fecha: 2026-09-01
-- Autor: Antigravity / ATLAS-TECH
-- Contexto: Resolución de Bug 42703 (e.price_per_adult) y Matriz de Proveedores
-- ═══════════════════════════════════════════════════════════════════

-- ─── 1. CORRECCIÓN RPC: get_excursions_by_hotel_slug ───────────────
-- Corrige el error 42703 reemplazando e.price_per_adult por e.price_base_usd
-- y vincula por coincidencia de destino/zona entre hotel y excursión.

CREATE OR REPLACE FUNCTION public.get_excursions_by_hotel_slug(p_hotel_slug text)
RETURNS jsonb AS $$
DECLARE
  v_destination text;
  v_result jsonb;
BEGIN
  -- 1. Obtener la ubicación/destino del hotel
  SELECT destination INTO v_destination
  FROM public.hotels_master
  WHERE slug = p_hotel_slug
  LIMIT 1;

  IF v_destination IS NULL THEN
    v_destination := 'Punta Cana'; -- Fallback estándar
  END IF;

  -- 2. Consultar excursiones activas en la misma zona geográfica
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', e.id,
      'slug', e.slug,
      'name', e.name,
      'description', e.description,
      'location', e.location,
      'zone', e.zone,
      'price_base_usd', e.price_base_usd,
      'price_child_usd', e.price_child_usd,
      'duration', e.duration,
      'rating', e.rating,
      'reviews_count', e.reviews_count,
      'image_url', e.image_url,
      'images', e.images,
      'highlights', e.highlights,
      'operator_name', e.operator_name,
      'is_featured', e.is_featured,
      'plans', (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', p.id,
            'slug', p.slug,
            'name', p.name,
            'description', p.description,
            'price_adult_usd', p.price_adult_usd,
            'price_child_usd', p.price_child_usd,
            'duration_label', p.duration_label,
            'includes', p.includes,
            'excludes', p.excludes
          ) ORDER BY p.sort_order ASC
        )
        FROM public.excursion_plans p
        WHERE p.excursion_id = e.id AND p.is_active = true
      )
    ) ORDER BY e.is_featured DESC, e.rating DESC NULLS LAST
  ) INTO v_result
  FROM public.excursions e
  WHERE e.is_active = true
    AND (
      e.location ILIKE '%' || v_destination || '%'
      OR v_destination ILIKE '%' || e.location || '%'
      OR e.zone = 'punta_cana' -- Cobertura por defecto para RD
    );

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE;


-- ─── 2. TABLA CANÓNICA: public.suppliers (MATRIZ DE SUMINISTRO) ───
-- Unifica la identidad relacional de proveedores síncronos y asíncronos

CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'wholesaler', 'local_operator', 'xml_broker'
    contact_email TEXT,
    contact_phone TEXT,
    contract_status TEXT DEFAULT 'pending', -- 'active', 'pending', 'expired'
    contract_version TEXT DEFAULT 'v1.0',
    commission_model TEXT DEFAULT 'net_markup',
    cutoff_default_hours INT DEFAULT 24,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Seed de proveedores fundacionales ya presentes en código y catálogo
INSERT INTO public.suppliers (code, name, type, contract_status, commission_model)
VALUES 
    ('DOLPHIN_ISLAND', 'Dolphin Island Park', 'local_operator', 'active', 'net_markup'),
    ('OCEAN_WORLD', 'Ocean World Adventure Park', 'local_operator', 'active', 'net_markup'),
    ('CARIBBEAN_LAKE', 'Caribbean Lake Park', 'local_operator', 'active', 'net_markup'),
    ('VDT', 'VDT Mayorista Receptivo', 'wholesaler', 'active', 'net_markup'),
    ('OPERAHOTEL', 'Opera Hotel Receptivo', 'wholesaler', 'active', 'net_markup'),
    ('GOGLOBAL', 'GoGlobal Travel API', 'xml_broker', 'pending', 'net_markup')
ON CONFLICT (code) DO NOTHING;


-- ─── 3. EXTENSIÓN CHECKOUT EN BOOKINGS: excursion_plan_id ─────────
-- Permite que la unidad seleccionable de excursiones tenga soporte DDL nativo
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'bookings' 
          AND column_name = 'excursion_plan_id'
    ) THEN
        ALTER TABLE public.bookings 
        ADD COLUMN excursion_plan_id UUID REFERENCES public.excursion_plans(id);
    END IF;
END $$;
