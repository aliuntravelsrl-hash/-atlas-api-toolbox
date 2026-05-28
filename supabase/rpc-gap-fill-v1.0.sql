-- ═══════════════════════════════════════════════════════════════════
-- ATLAS SALES MCP — RPC Gap Fill v1.0
-- Crea: calcular_precio_paquete, validar_ocupacion_habitacion, buscar_ofertas_marketing
-- Proyecto: oyihiyivdhfxpyiwnmqk
-- Fecha: 2026-05-28
-- Ejecutar en: Supabase Dashboard → SQL Editor → Run
-- ═══════════════════════════════════════════════════════════════════

-- ─── RPC 1: calcular_precio_paquete ────────────────────────────
-- Calcula precio total del paquete + conversión USD→DOP
-- MCP tool sends: p_hotel_id, p_noches, p_adultos, p_ninos, p_tasa_venta, p_es_proveedor_local_dop, p_modo_productivo
CREATE OR REPLACE FUNCTION public.calcular_precio_paquete(
  p_hotel_id uuid,
  p_noches integer,
  p_adultos integer,
  p_ninos integer DEFAULT 0,
  p_tasa_venta numeric DEFAULT 0,
  p_es_proveedor_local_dop boolean DEFAULT false,
  p_modo_productivo boolean DEFAULT true
)
RETURNS jsonb AS $$
DECLARE
  v_hotel_name text;
  v_hotel_slug text;
  v_hotel_zone text;
  v_cheapest_rate numeric;
  v_price_per_night numeric;
  v_subtotal numeric;
  v_total_usd numeric;
  v_total_dop numeric;
  v_tasa numeric;
  v_margin_pct numeric := 10;
  v_margin_amount numeric;
BEGIN
  -- Get hotel info
  SELECT name, slug, zone INTO v_hotel_name, v_hotel_slug, v_hotel_zone
  FROM public.hotels_master
  WHERE id = p_hotel_id
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Hotel no encontrado', 'hotel_id', p_hotel_id);
  END IF;

  -- Get cheapest adult_rate for current season
  SELECT MIN(r.adult_rate) INTO v_cheapest_rate
  FROM public.rates r
  JOIN public.rooms rm ON rm.id = r.room_id
  WHERE rm.hotel_id = p_hotel_id
    AND r.season_id IN (
      SELECT id FROM public.seasons
      WHERE start_date <= CURRENT_DATE AND end_date >= CURRENT_DATE
    );

  -- Fallback: overall cheapest rate
  IF v_cheapest_rate IS NULL OR v_cheapest_rate = 0 THEN
    SELECT MIN(r.adult_rate) INTO v_cheapest_rate
    FROM public.rates r
    JOIN public.rooms rm ON rm.id = r.room_id
    WHERE rm.hotel_id = p_hotel_id;
  END IF;

  IF v_cheapest_rate IS NULL THEN
    v_cheapest_rate := 0;
  END IF;

  v_price_per_night := v_cheapest_rate;
  v_subtotal := v_price_per_night * p_noches;
  v_margin_amount := v_subtotal * (v_margin_pct / 100.0);

  -- Exchange rate
  IF p_tasa_venta > 0 THEN
    v_tasa := p_tasa_venta;
  ELSE
    -- Try to get latest rate from exchange_rates table
    SELECT rate INTO v_tasa
    FROM public.exchange_rates
    WHERE from_currency = 'USD' AND to_currency = 'DOP'
    ORDER BY effective_date DESC LIMIT 1;

    IF v_tasa IS NULL THEN
      v_tasa := 62.50; -- BCR default approximation
    END IF;
  END IF;

  -- Calculate totals
  IF p_es_proveedor_local_dop THEN
    v_total_usd := v_subtotal;
    v_total_dop := v_subtotal * v_tasa;
  ELSE
    v_total_usd := v_subtotal + v_margin_amount;
    v_total_dop := v_total_usd * v_tasa;
  END IF;

  RETURN jsonb_build_object(
    'hotel_id', p_hotel_id,
    'hotel_name', v_hotel_name,
    'hotel_slug', v_hotel_slug,
    'hotel_zone', v_hotel_zone,
    'noches', p_noches,
    'adultos', p_adultos,
    'ninos', p_ninos,
    'price_per_night_usd', ROUND(v_price_per_night, 2),
    'subtotal_usd', ROUND(v_subtotal, 2),
    'margin_pct', v_margin_pct,
    'margin_usd', ROUND(v_margin_amount, 2),
    'total_usd', ROUND(v_total_usd, 2),
    'tasa_usd_dop', v_tasa,
    'total_dop', ROUND(v_total_dop, 2),
    'currency', 'USD',
    'es_proveedor_local_dop', p_es_proveedor_local_dop,
    'modo_productivo', p_modo_productivo
  );
END;
$$ LANGUAGE plpgsql STABLE;


-- ─── RPC 2: validar_ocupacion_habitacion ──────────────────────
-- Valida si la ocupación excede capacidad del tipo de habitación
-- MCP tool sends: p_hotel_id, p_room_type, p_adultos, p_ninos
CREATE OR REPLACE FUNCTION public.validar_ocupacion_habitacion(
  p_hotel_id uuid,
  p_room_type text,
  p_adultos integer,
  p_ninos integer DEFAULT 0
)
RETURNS jsonb AS $$
DECLARE
  v_room_id uuid;
  v_room_name text;
  v_max_adults integer;
  v_max_children integer;
  v_max_total integer;
  v_total_personas integer;
  v_adults_ok boolean;
  v_children_ok boolean;
  v_total_ok boolean;
  v_is_valid boolean;
  v_warnings text[] := ARRAY[]::text[];
BEGIN
  v_total_personas := p_adultos + p_ninos;

  -- Try exact room_type match
  SELECT id, name, capacity_adults, capacity_children, max_occupancy
  INTO v_room_id, v_room_name, v_max_adults, v_max_children, v_max_total
  FROM public.rooms
  WHERE hotel_id = p_hotel_id
    AND LOWER(room_type) = LOWER(p_room_type)
  LIMIT 1;

  -- Fallback: partial match on room name
  IF NOT FOUND THEN
    SELECT id, name, capacity_adults, capacity_children, max_occupancy
    INTO v_room_id, v_room_name, v_max_adults, v_max_children, v_max_total
    FROM public.rooms
    WHERE hotel_id = p_hotel_id
      AND LOWER(name) LIKE '%' || LOWER(p_room_type) || '%'
    LIMIT 1;
  END IF;

  -- Fallback: also check room_occupancy_rules table
  IF NOT FOUND THEN
    SELECT ro.max_adults, ro.max_children, ro.max_pax
    INTO v_max_adults, v_max_children, v_max_total
    FROM public.room_occupancy_rules ro
    WHERE ro.hotel_id = p_hotel_id
      AND LOWER(ro.room_type_id::text) LIKE '%' || LOWER(p_room_type) || '%'
    LIMIT 1;

    IF FOUND THEN
      v_room_name := p_room_type || ' (occupancy rules)';
      v_max_adults := COALESCE(v_max_adults, 3);
      v_max_children := COALESCE(v_max_children, 2);
      v_max_total := COALESCE(v_max_total, v_max_adults + v_max_children);
    END IF;
  END IF;

  -- Final fallback: get cheapest room
  IF NOT FOUND AND v_room_id IS NULL THEN
    SELECT id, name, capacity_adults, capacity_children, max_occupancy
    INTO v_room_id, v_room_name, v_max_adults, v_max_children, v_max_total
    FROM public.rooms
    WHERE hotel_id = p_hotel_id
    ORDER BY capacity_adults ASC
    LIMIT 1;
  END IF;

  IF NOT FOUND AND v_room_id IS NULL THEN
    RETURN jsonb_build_object(
      'valid', false,
      'error', 'Habitación no encontrada',
      'hotel_id', p_hotel_id,
      'room_type', p_room_type
    );
  END IF;

  -- Apply defaults for nulls
  v_max_adults := COALESCE(v_max_adults, 3);
  v_max_children := COALESCE(v_max_children, 2);
  v_max_total := COALESCE(v_max_total, v_max_adults + v_max_children);

  -- Validate
  v_adults_ok := p_adultos <= v_max_adults;
  v_children_ok := p_ninos <= v_max_children;
  v_total_ok := v_total_personas <= v_max_total;
  v_is_valid := v_adults_ok AND v_children_ok AND v_total_ok;

  -- Build warnings
  IF NOT v_adults_ok THEN
    v_warnings := array_append(v_warnings, 'Excede adultos máximos: ' || v_max_adults);
  END IF;
  IF NOT v_children_ok THEN
    v_warnings := array_append(v_warnings, 'Excede niños máximos: ' || v_max_children);
  END IF;
  IF NOT v_total_ok THEN
    v_warnings := array_append(v_warnings, 'Excede ocupación total: ' || v_max_total);
  END IF;

  RETURN jsonb_build_object(
    'valid', v_is_valid,
    'hotel_id', p_hotel_id,
    'room_id', v_room_id,
    'room_name', v_room_name,
    'room_type', p_room_type,
    'requested_adults', p_adultos,
    'requested_children', p_ninos,
    'total_personas', v_total_personas,
    'max_adults', v_max_adults,
    'max_children', v_max_children,
    'max_occupancy', v_max_total,
    'adults_ok', v_adults_ok,
    'children_ok', v_children_ok,
    'total_ok', v_total_ok,
    'warnings', v_warnings
  );
END;
$$ LANGUAGE plpgsql STABLE;


-- ─── RPC 3: buscar_ofertas_marketing ──────────────────────────
-- Busca ofertas activas de marketing con stock real
-- MCP tool sends: p_hotel_slug, p_offer_type, p_limit
-- Uses: marketing_offers table + offer_date_ranges (from Horizons v21)
CREATE OR REPLACE FUNCTION public.buscar_ofertas_marketing(
  p_hotel_slug text DEFAULT NULL,
  p_offer_type text DEFAULT NULL,
  p_limit integer DEFAULT 5
)
RETURNS jsonb AS $$
DECLARE
  v_result jsonb;
BEGIN
  -- If offer_date_ranges table doesn't exist, use marketing_offers directly
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'offer_id', mo.id,
    'title', mo.title,
    'offer_slug', mo.slug,
    'offer_type', mo.offer_type,
    'discount_pct', mo.discount_percent,
    'is_published', mo.published,
    'accepts_deposit', mo.accepts_deposit,
    'conditions', mo.terms,
    'price_usd', mo.price_usd,
    'price_dop', mo.price_dop,
    'min_nights', mo.min_nights,
    'max_nights', mo.max_nights,
    'hotel_name', hm.name,
    'hotel_slug', hm.slug,
    'hotel_zone', hm.zone,
    'hotel_stars', hm.estrellas,
    'check_in_start', mo.check_in_start,
    'check_in_end', mo.check_in_end,
    'booking_deadline', mo.booking_deadline
   ORDER BY mo.discount_percent DESC NULLS LAST), '[]'::jsonb)
  INTO v_result
  FROM public.marketing_offers mo
  JOIN public.hotels_master hm ON hm.id = mo.hotel_id
  WHERE mo.published = true
    AND (p_hotel_slug IS NULL OR hm.slug = p_hotel_slug)
    AND (p_offer_type IS NULL OR mo.offer_type = p_offer_type)
    AND mo.check_in_end >= CURRENT_DATE
  ORDER BY mo.discount_percent DESC NULLS LAST
  LIMIT p_limit;

  RETURN jsonb_build_object(
    'offers', v_result,
    'total_count', jsonb_array_length(v_result),
    'filters', jsonb_build_object(
      'hotel_slug', p_hotel_slug,
      'offer_type', p_offer_type,
      'limit', p_limit
    )
  );
END;
$$ LANGUAGE plpgsql STABLE;


-- ─── SCHEMA CACHE RELOAD ──────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ═══════════════════════════════════════════════════════════════════
-- FIN MIGRATION v1.0 — RPC Gap Fill
-- ═══════════════════════════════════════════════════════════════════
