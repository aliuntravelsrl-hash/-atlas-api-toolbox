-- ═══════════════════════════════════════════════════════════════════
-- SUPPLIER INGESTION — Migration v1.1
-- EVO EVOLUTION SPECIFICATION — Supplier Ingestion v1 (04 Sep 2026)
-- Autorizado por: Director Aldo Hilario — APPROVE: GENERATE MIGRATION FILE ONLY
-- Curator/Notario: Antigravity — dictamen v1.0 03 Sep 2026, ajustes v1.1 04 Sep 2026
-- Ejecutor: ATLAS-TECH (Claude) — dentro de frontera Supabase/Data Model exclusivamente
--
-- CAMBIOS v1.1 vs v1.0 (commit f876b408) — SOLO 3 AJUSTES TECNICOS,
-- SIN CAMBIO ARQUITECTONICO, segun dictamen del Curator:
--   1. Migracion envuelta en BEGIN/COMMIT para atomicidad real
--   2. UNIQUE(raw_evidence_id, attempt_number) + CHECK(attempt_number > 0)
--   3. Prueba reproducible via bloque DO (sin variables :sustitucion,
--      sin copiar IDs manualmente entre pasos)
--
-- Crea: raw_supplier_evidence, ingestion_attempts
-- Extiende: atlas_block_inventory (raw_evidence_id, provider_code)
-- Proyecto: oyihiyivdhfxpyiwnmqk
-- Fecha: 2026-09-04
--
-- ESTADO: NO EJECUTADA. Archivo generado para revision del Director/
-- Curator antes de autorizar ejecucion real (EVO Seccion 20).
--
-- NO AUTORIZADO EN ESTA MIGRACION (fuera de frontera / pendiente):
--   - Backfill de las 776 filas historicas de atlas_block_inventory
--   - Cualquier cambio a ovr_instances / ovr_trace (UNKNOWN preservado,
--     Regla E4 del EVO - OVR no se usa como lineage comercial)
--   - Conexion de n8n / Gemini / cualquier pipeline
--   - Cambios de codigo o frontend
-- ═══════════════════════════════════════════════════════════════════

BEGIN;

-- ─── TABLA 1: raw_supplier_evidence ────────────────────────────
-- Responsabilidad EXCLUSIVA: preservar la evidencia original del
-- proveedor tal como llego, ANTES de cualquier parser (EVO Seccion 5).
-- Inmutable / append-only desde el instante de RECEIVE. No contiene
-- ningun campo cuyo significado dependa de que el parser haya corrido.
CREATE TABLE IF NOT EXISTS public.raw_supplier_evidence (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identidad del proveedor: PROVIDER HINT != PROVIDER IDENTITY (EVO Sec.9)
  provider_code       text REFERENCES public.local_providers(provider_code),
  provider_hint       text,

  -- Contenido crudo original - unicos campos de evidencia real
  source_channel      text NOT NULL
                       CHECK (source_channel IN ('telegram','email','pdf','manual','api')),
  original_content    text,              -- texto plano tal cual llego
  raw_payload         jsonb,             -- payload crudo completo del canal/webhook
  file_reference       text,              -- URL en Supabase Storage si es PDF/imagen
  file_mime_type         text,

  received_at             timestamptz NOT NULL DEFAULT now(),
  created_at               timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.raw_supplier_evidence IS
  'Evidencia cruda de proveedor - PRIMER EVENTO PERSISTENTE, antes de cualquier parser. Inmutable, append-only. EVO Supplier Ingestion v1, Seccion 6.1.';

CREATE INDEX IF NOT EXISTS idx_raw_evidence_provider  ON public.raw_supplier_evidence(provider_code);
CREATE INDEX IF NOT EXISTS idx_raw_evidence_channel   ON public.raw_supplier_evidence(source_channel);
CREATE INDEX IF NOT EXISTS idx_raw_evidence_received  ON public.raw_supplier_evidence(received_at DESC);

-- Proteccion append-only real (mismo patron ya usado en
-- crm_activities/crm_event_log)
CREATE OR REPLACE FUNCTION public.enforce_raw_evidence_insert_only()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'raw_supplier_evidence es append-only: solo INSERT permitido (EVO Sec.6.1, evidencia inmutable)';
END;
$$;

DROP TRIGGER IF EXISTS trg_raw_evidence_no_update ON public.raw_supplier_evidence;
CREATE TRIGGER trg_raw_evidence_no_update
  BEFORE UPDATE ON public.raw_supplier_evidence
  FOR EACH ROW EXECUTE FUNCTION public.enforce_raw_evidence_insert_only();

DROP TRIGGER IF EXISTS trg_raw_evidence_no_delete ON public.raw_supplier_evidence;
CREATE TRIGGER trg_raw_evidence_no_delete
  BEFORE DELETE ON public.raw_supplier_evidence
  FOR EACH ROW EXECUTE FUNCTION public.enforce_raw_evidence_insert_only();

ALTER TABLE public.raw_supplier_evidence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_role_full_access" ON public.raw_supplier_evidence;
CREATE POLICY "service_role_full_access"
  ON public.raw_supplier_evidence FOR ALL TO service_role
  USING (true) WITH CHECK (true);
-- Sin politica para anon/authenticated - bloqueado por defecto.


-- ─── TABLA 2: ingestion_attempts ───────────────────────────────
-- Responsabilidad EXCLUSIVA: estado del procesamiento/parsing de una
-- raw_supplier_evidence. Mutable (a diferencia de la evidencia).
-- Un fallo de Gemini NO destruye la evidencia asociada (EVO Sec.14).
-- Soporta reintentos (attempt_number), con unicidad garantizada
-- por evidencia (AJUSTE v1.1 - dictamen Curator punto 2).
CREATE TABLE IF NOT EXISTS public.ingestion_attempts (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_evidence_id     uuid NOT NULL REFERENCES public.raw_supplier_evidence(id),

  parser_used         text NOT NULL,
  attempt_number      integer NOT NULL DEFAULT 1
                       CHECK (attempt_number > 0),
  execution_state     text NOT NULL DEFAULT 'started'
                       CHECK (execution_state IN ('started','succeeded','failed')),

  parser_output        jsonb,
  parser_error          text,

  started_at             timestamptz NOT NULL DEFAULT now(),
  completed_at            timestamptz,

  created_at               timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT uq_ingestion_attempts_evidence_attempt
    UNIQUE (raw_evidence_id, attempt_number)
);

COMMENT ON TABLE public.ingestion_attempts IS
  'Intentos de procesamiento/parsing de raw_supplier_evidence. Mutable. Preserva historial completo incluso de intentos fallidos. UNIQUE(raw_evidence_id, attempt_number) evita duplicados de reintento. EVO Supplier Ingestion v1, Seccion 7.';

CREATE INDEX IF NOT EXISTS idx_ingestion_attempts_evidence ON public.ingestion_attempts(raw_evidence_id);
CREATE INDEX IF NOT EXISTS idx_ingestion_attempts_state    ON public.ingestion_attempts(execution_state);

-- Permite UPDATE (started->succeeded/failed) pero NO DELETE -
-- se preserva el historial completo, incluso los fallidos
CREATE OR REPLACE FUNCTION public.enforce_ingestion_attempts_no_delete()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'ingestion_attempts no permite DELETE - se preserva historial de intentos, incluso fallidos (EVO Sec.14)';
END;
$$;

DROP TRIGGER IF EXISTS trg_ingestion_attempts_no_delete ON public.ingestion_attempts;
CREATE TRIGGER trg_ingestion_attempts_no_delete
  BEFORE DELETE ON public.ingestion_attempts
  FOR EACH ROW EXECUTE FUNCTION public.enforce_ingestion_attempts_no_delete();

ALTER TABLE public.ingestion_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_role_full_access" ON public.ingestion_attempts;
CREATE POLICY "service_role_full_access"
  ON public.ingestion_attempts FOR ALL TO service_role
  USING (true) WITH CHECK (true);


-- ─── EXTENSION: atlas_block_inventory ──────────────────────────
-- Lineage hacia raw_supplier_evidence + identidad estructurada de
-- proveedor. Ambas columnas NULLABLE - las 776 filas historicas
-- quedan con NULL, sin backfill automatico (EVO Sec.9, Regla E1/E2/E3).
ALTER TABLE public.atlas_block_inventory
  ADD COLUMN IF NOT EXISTS raw_evidence_id uuid REFERENCES public.raw_supplier_evidence(id),
  ADD COLUMN IF NOT EXISTS provider_code   text REFERENCES public.local_providers(provider_code);

COMMENT ON COLUMN public.atlas_block_inventory.raw_evidence_id IS
  'Lineage hacia raw_supplier_evidence.id. NULL para filas historicas anteriores a esta migracion - no se reconstruye lineage retroactivo (EVO Regla E2).';
COMMENT ON COLUMN public.atlas_block_inventory.provider_code IS
  'FK formal a local_providers. NULL para filas historicas - sin backfill automatico (EVO Seccion 9, Regla E3).';

CREATE INDEX IF NOT EXISTS idx_abi_raw_evidence   ON public.atlas_block_inventory(raw_evidence_id);
CREATE INDEX IF NOT EXISTS idx_abi_provider_code  ON public.atlas_block_inventory(provider_code);

COMMIT;


-- ═══════════════════════════════════════════════════════════════════
-- PRUEBA DE MIGRACION REPRODUCIBLE (AJUSTE v1.1 - dictamen Curator
-- punto 3). Bloque DO autocontenido: sin variables :sustitucion,
-- sin copiar IDs manualmente. Usa RAISE EXCEPTION para fallar ruidoso
-- si cualquier asercion no se cumple. Se ejecuta dentro de su propia
-- transaccion con ROLLBACK explicito al final - no persiste nada.
--
-- Ejecutar como bloque independiente, DESPUES de aplicar la migracion.
-- ═══════════════════════════════════════════════════════════════════
/*
BEGIN;

DO $$
DECLARE
  v_count_before        integer;
  v_count_after_null     integer;
  v_evidence_id           uuid;
  v_content_check          text;
  v_lineage_hotel            text;
  v_lineage_content            text;
  v_lineage_attempts             integer;
  v_fk_provider_failed              boolean := false;
  v_fk_evidence_failed                boolean := false;
  v_update_blocked                      boolean := false;
  v_delete_blocked                        boolean := false;
  v_unique_blocked                          boolean := false;
BEGIN
  -- (a) Integridad: contar filas de atlas_block_inventory ANTES
  SELECT count(*) INTO v_count_before FROM atlas_block_inventory;

  -- (b) RECEIVE: insertar evidencia SIN que el parser haya corrido
  INSERT INTO raw_supplier_evidence (source_channel, original_content)
  VALUES ('telegram', 'TEST: bloqueo Barcelo 10 hab DBL')
  RETURNING id INTO v_evidence_id;

  -- (c) Intento fallido (attempt_number=1)
  INSERT INTO ingestion_attempts (raw_evidence_id, parser_used, attempt_number, execution_state, parser_error, completed_at)
  VALUES (v_evidence_id, 'gemini-1.5-flash', 1, 'failed', 'TEST: timeout simulado', now());

  -- (d) Evidencia original sobrevive el fallo
  SELECT original_content INTO v_content_check FROM raw_supplier_evidence WHERE id = v_evidence_id;
  IF v_content_check IS DISTINCT FROM 'TEST: bloqueo Barcelo 10 hab DBL' THEN
    RAISE EXCEPTION 'FALLO (d): la evidencia no sobrevivio intacta al intento fallido';
  END IF;

  -- (e) Reintento exitoso (attempt_number=2) - UNIQUE debe permitirlo
  INSERT INTO ingestion_attempts (raw_evidence_id, parser_used, attempt_number, execution_state, parser_output, completed_at)
  VALUES (v_evidence_id, 'gemini-1.5-flash', 2, 'succeeded', '{"hotel":"Barcelo","rooms":10}'::jsonb, now());

  -- (f) UNIQUE(raw_evidence_id, attempt_number) debe rechazar duplicado
  BEGIN
    INSERT INTO ingestion_attempts (raw_evidence_id, parser_used, attempt_number, execution_state)
    VALUES (v_evidence_id, 'gemini-1.5-flash', 2, 'started');
  EXCEPTION WHEN unique_violation THEN
    v_unique_blocked := true;
  END;
  IF NOT v_unique_blocked THEN
    RAISE EXCEPTION 'FALLO (f): UNIQUE(raw_evidence_id, attempt_number) no bloqueo un duplicado';
  END IF;

  -- (g) CHECK(attempt_number > 0) debe rechazar attempt_number=0
  BEGIN
    INSERT INTO ingestion_attempts (raw_evidence_id, parser_used, attempt_number, execution_state)
    VALUES (v_evidence_id, 'gemini-1.5-flash', 0, 'started');
  EXCEPTION WHEN check_violation THEN
    NULL; -- esperado
  END;

  -- (h) Persistir representacion comercial final con lineage
  INSERT INTO atlas_block_inventory (hotel_slug, check_in, check_out, room_category, provider_code, raw_evidence_id)
  VALUES ('test-hotel-do-block', '2026-10-01', '2026-10-05', 'DBL', 'GEN', v_evidence_id);

  -- (i) FK debe rechazar provider_code invalido
  BEGIN
    INSERT INTO atlas_block_inventory (hotel_slug, check_in, check_out, room_category, provider_code)
    VALUES ('test-hotel-2', '2026-10-01', '2026-10-05', 'DBL', 'CODIGO-FALSO');
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_provider_failed := true;
  END;
  IF NOT v_fk_provider_failed THEN
    RAISE EXCEPTION 'FALLO (i): FK de provider_code no rechazo un codigo invalido';
  END IF;

  -- (j) FK debe rechazar raw_evidence_id invalido
  BEGIN
    INSERT INTO atlas_block_inventory (hotel_slug, check_in, check_out, room_category, raw_evidence_id)
    VALUES ('test-hotel-3', '2026-10-01', '2026-10-05', 'DBL', gen_random_uuid());
  EXCEPTION WHEN foreign_key_violation THEN
    v_fk_evidence_failed := true;
  END;
  IF NOT v_fk_evidence_failed THEN
    RAISE EXCEPTION 'FALLO (j): FK de raw_evidence_id no rechazo un id invalido';
  END IF;

  -- (k) Append-only: UPDATE en evidencia debe fallar
  BEGIN
    UPDATE raw_supplier_evidence SET original_content = 'hackeado' WHERE id = v_evidence_id;
  EXCEPTION WHEN OTHERS THEN
    v_update_blocked := true;
  END;
  IF NOT v_update_blocked THEN
    RAISE EXCEPTION 'FALLO (k): UPDATE en raw_supplier_evidence no fue bloqueado';
  END IF;

  -- (l) DELETE en ingestion_attempts debe fallar (preserva fallidos)
  BEGIN
    DELETE FROM ingestion_attempts WHERE raw_evidence_id = v_evidence_id AND execution_state = 'failed';
  EXCEPTION WHEN OTHERS THEN
    v_delete_blocked := true;
  END;
  IF NOT v_delete_blocked THEN
    RAISE EXCEPTION 'FALLO (l): DELETE en ingestion_attempts no fue bloqueado';
  END IF;

  -- (m) Lineage completo verificable en ambos sentidos
  SELECT abi.hotel_slug, rse.original_content,
         (SELECT count(*) FROM ingestion_attempts WHERE raw_evidence_id = rse.id)
    INTO v_lineage_hotel, v_lineage_content, v_lineage_attempts
  FROM atlas_block_inventory abi
  JOIN raw_supplier_evidence rse ON rse.id = abi.raw_evidence_id
  WHERE abi.hotel_slug = 'test-hotel-do-block';

  IF v_lineage_hotel IS NULL OR v_lineage_attempts <> 2 THEN
    RAISE EXCEPTION 'FALLO (m): lineage incompleto - hotel=%, intentos=%', v_lineage_hotel, v_lineage_attempts;
  END IF;

  -- (n) Filas historicas siguen sin tocar (solo crecio por la fila de prueba)
  SELECT count(*) INTO v_count_after_null FROM atlas_block_inventory WHERE raw_evidence_id IS NULL;
  IF v_count_after_null <> v_count_before THEN
    RAISE EXCEPTION 'FALLO (n): se modificaron filas historicas - antes=%, con raw_evidence_id NULL despues=%', v_count_before, v_count_after_null;
  END IF;

  RAISE NOTICE 'TODAS LAS PRUEBAS PASARON: (a)-(n) OK. lineage_hotel=%, intentos=%, historicas_intactas=%',
    v_lineage_hotel, v_lineage_attempts, v_count_after_null;
END $$;

ROLLBACK;  -- nada de esto persiste, es solo verificacion
*/

-- ═══════════════════════════════════════════════════════════════════
-- REVERSIBILIDAD (si se aplica y se necesita deshacer - aditivo puro,
-- nunca modifica filas historicas de atlas_block_inventory)
-- ═══════════════════════════════════════════════════════════════════
/*
BEGIN;
DROP TABLE IF EXISTS public.ingestion_attempts;
ALTER TABLE public.atlas_block_inventory DROP COLUMN IF EXISTS raw_evidence_id;
ALTER TABLE public.atlas_block_inventory DROP COLUMN IF EXISTS provider_code;
DROP TABLE IF EXISTS public.raw_supplier_evidence;
COMMIT;
*/
