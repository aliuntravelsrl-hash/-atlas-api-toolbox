# PROMPT ATLAS-TECH — CIERRE SOP E2E
# Prioridad: SOP VENTAS E2E OPERATIVO end-to-end
# Emitido por HERMES · 22 MAY 2026 · Orden del Director

═════════════════════════════════════════════════════════════
OBJETIVO: CERRAR EL SOP E2E EN 1 SESIÓN
═════════════════════════════════════════════════════════════

El SOP-VENTAS-E2E-v1 (Notion page: 365293f4-6b24-81b0-8e8d-edfb9ad3dcdc)
define 13 pasos. Hoy solo funcionan 8. Cierra los 5 gaps restantes.

OBJETIVO MEDIBLE: Un lead entra por WhatsApp → recibe cotización PDF → 
aprueba → sube comprobante → se valida → se genera voucher PDF → 
notificación al Director. TODO sin intervención humana excepto Greenlight Gate.

═════════════════════════════════════════════════════════════
ESTADO ACTUAL — LO QUE FUNCIONA ✅
═════════════════════════════════════════════════════════════

n8n WORKFLOWS ACTIVOS (11/11 core):
  🟢 WF-HORIZONS-BOOKING-API-v1 (fkeayENDXynocb8I)
     POST /webhook/horizons-booking-api
     Actions: GET_ROOMS, QUOTE, CREATE_BOOKING, CREATE_BOOKING_FROM_OFFER
     ⚠️ ÚLTIMAS 3 EJECUCIONES FALLARON — necesita diagnóstico

  🟢 WF-COTIZACION-GOTENBERG-v2 (Da46ZVQGRpdgaI02)
     POST /webhook/aliun-cotizacion
     Gotenberg → PDF → Supabase Storage/cotizaciones/

  🟢 WF-COTIZACION-LANDING-v1 (K0Zexy6HMV1ZZuZW)
     GET /webhook/cotizacion-landing
     HTML landing page branded

  🟢 WF-VOUCHER-GOTENBERG-v1 (T89xnmHoKMrFMhnT)
     POST /webhook/aliun-voucher
     Gotenberg → PDF → Supabase Storage

  🟢 WF-DEPOSITO-APROBACION-v1 (2SMN7WB0pzjzsJTt)
     POST /webhook/aliun-deposito-aprobado

  🟢 WF-TOOL-VALIDAR-COMPROBANTE-v1 (QwPpyg5FB9C2v1tR)
     POST /webhook/validar-comprobante

  🟢 WF-LEAD-CAPTURE-v1 (Mb0KLthZ954xTcw3)
     POST /webhook/aliun-lead

  🟢 WF-SALES-FULFILLMENT-HANDLER-v2 (UrFIhdYw7EOLFnQd)
     POST /webhook/sales-fulfillment-notify

  🟢 WF-OPS-BOOKING-FULFILLMENT-v2 (HVJHikQu5WH8rWHW)
     Booking fulfillment B2B

  🟢 WF-TOOL-REGISTRAR-INTERES-v1 (HgqbsMVwQikr5gWh)
     POST /webhook/registrar-interes

  🟢 Flujo K — Confirmación + Estado Cuenta (clJ7YfPfzOLZSS0P)
     POST /webhook/aliun-confirmacion
     PDFMonkey → PDF → Supabase Storage/confirmaciones/ → Email

WORKFLOWS NUEVOS (creados por Hermes, requieren configuración en n8n UI):
  ⚠️ WF-MCP-ANALISIS-FINANCIERO-v1 (J9F5paaLfbbHQ09y)
     POST /webhook/mcp-analisis-financiero
     → Agregar credenciales Supabase al nodo "Get Bookings" → Activar

  ⚠️ WF-WA-INCOMING-v1 (IJBhKHTX7gzMxfVi)
     POST /webhook/aliun-wa-incoming
     → Ya activo, conectar a WF-LEAD-CAPTURE-v1

  🟢 WF-MCP-HEALTH-v1 (miLKRhBOF9b8MCxZ)
     GET /webhook/mcp-health → Activo

  ⚠️ ALIUN — Conversion Leads CRM→Meta CAPI (QK1ZF7Ix5UJWfNYV)
     → Agregar creds Supabase + Meta CAPI → Activar

  ⚠️ WF-HERMES-GUARDIAN-v1 (wT4AD9VhFZc0DfGH)
     → Reparar schedule trigger ("Invalid interval") → Activar

MCP SERVER: atlas-sales-mcp v1.3.0
  13 tools registradas en código:
  1. consultar_disponibilidad — Supabase RPC directo
  2. buscar_hoteles — /webhook/mcp-buscar-hoteles
  3. generar_cotizacion_pdf — /webhook/aliun-cotizacion
  4. registrar_deposito — /webhook/registrar-interes ✅ FIX APLICADO
  5. validar_comprobante — /webhook/validar-comprobante ✅ FIX APLICADO
  6. obtener_galeria_hotel — /webhook/mcp-obtener-galeria-hotel
  7. generar_post_creativo — /webhook/mcp-generar-post-creativo
  8. calcular_cotizacion — Supabase RPC directo
  9. analisis_financiero — /webhook/mcp-analisis-financiero (NUEVO)
  10. calcular_precio_paquete — Supabase RPC directo
  11. validar_ocupacion_habitacion — Supabase RPC directo
  12. buscar_ofertas_marketing — Supabase RPC directo
  13. consultar_reserva — Supabase RPC directo

  Repositorio: aliuntravelsrl-hash/atlas-sales-mcp
  Último commit: 778a2e5 (fix webhook paths)

FRONTEND (aliuntravelsrl.com):
  ✅ Fase 2 deploy — Checkout 3 pasos funcional
  ✅ Mission Control con datos reales Supabase
  ✅ Build compilando 4,033 módulos
  ✅ Repo PRIVADO: aliuntravelsrl-hash/atlas-booking-frontend-v2

═════════════════════════════════════════════════════════════
LOS 5 GAPS QUE CIERRAS HOY ❌→✅
═════════════════════════════════════════════════════════════

GAP 1: BOOKING API FALLA EN PRODUCCIÓN
  Síntoma: POST /webhook/horizons-booking-api retorna vacío
  Ejecuciones recientes: status=error (últimas 3)
  Antes funcionaba (retornaba ALN-HJUYED exitosamente)
  ACCIÓN:
    1. Abrir WF-HORIZONS-BOOKING-API-v1 en n8n
    2. Verificar nodo 03_GET_HOTEL_ID (HTTP request a Supabase)
    3. Verificar nodo 08B_CREATE_BOOKING_ROW (insert en bookings)
    4. Verificar nodo 08A_CREATE_LEAD (insert en crm_leads)
    5. Revisar credenciales Supabase en cada nodo
    6. Ejecutar manualmente desde n8n UI para ver el error exacto
    7. Fix → Test → Confirmar retorna booking_reference

GAP 2: COTIZACIÓN NO RETORNA LANDING_URL
  Síntoma: POST /webhook/aliun-cotizacion retorna vacío
  El MCP tool generar_cotizacion_pdf NECESITA recibir landing_url de vuelta
  ACCIÓN:
    1. Abrir WF-COTIZACION-GOTENBERG-v2 en n8n
    2. Verificar que el nodo de respuesta retorna:
       {
         "success": true,
         "landing_url": "https://n8n-n8n.xaruuo.easypanel.host/webhook/cotizacion-landing?ref=XXXX",
         "pdf_url": "https://oyihiyivdhfxpyiwnmqk.supabase.co/storage/v1/object/public/cotizaciones/XXXX_cotizacion.pdf",
         "id_cotizacion": "XXXX"
       }
    3. Si el workflow es async (responseMode="lastNode"), cambiar a 
       responseMode="responseNode" y agregar respondToWebhook ANTES de 
       operaciones lentas (Gotenberg)
    4. Test: curl POST → debe retornar JSON con landing_url

GAP 3: FLUJO COTIZACIÓN → BOOKING DESCONECTADO
  Síntoma: No hay bridge entre cotización y reserva
  ACCIÓN:
    1. En WF-COTIZACION-LANDING-v1, agregar botón "Confirmar Reserva"
       que llame a /webhook/horizons-booking-api?action=CREATE_BOOKING
    2. O: Agregar action=CREATE_BOOKING_FROM_QUOTE al booking API
       que use la id_cotizacion como referencia
    3. El flujo debe ser: Cotización PDF → Landing → Click Confirmar 
       → Booking creado → Redirect a /booking/confirm

GAP 4: ABONOS PARCIALES — NO EXISTE
  Síntoma: Solo hay validación de 1 comprobante. No hay registro 
  de abonos parciales ni estado de cuenta con saldo pendiente.
  ACCIÓN:
    1. Crear tabla Supabase: booking_payments
       - id, booking_id (FK), amount, currency, method, status, 
         proof_url, created_at, validated_by, validated_at
    2. Modificar WF-DEPOSITO-APROBACION-v1 para:
       - INSERT en booking_payments (no UPDATE directo en bookings)
       - Calcular total pagado vs total_amount
       - Si total_pagado >= total_amount → payment_status='paid'
       - Si no → payment_status='partial'
    3. Modificar Flujo K (Confirmación) para incluir:
       - Total reserva
       - Total abonado
       - Saldo pendiente
       - Próximo vencimiento
    4. Agregar MCP tool: registrar_abono
       - POST /webhook/registrar-interes con action='REGISTRAR_ABONO'

GAP 5: WA INCOMING → LEAD CAPTURE DESCONECTADO
  Síntoma: WF-WA-INCOMING-v1 recibe mensajes pero no los 
  redirige a WF-LEAD-CAPTURE-v1 ni al CRM
  ACCIÓN:
    1. Abrir WF-WA-INCOMING-v1 en n8n
    2. Agregar nodo HTTP Request que llame a 
       /webhook/aliun-lead con el payload del mensaje
    3. Agregar nodo Supabase insert en crm_leads
    4. Conectar respuesta al ALIUN WA Bot (Cloud API)
       POST https://graph.facebook.com/v23.0/{PHONE_NUMBER_ID}/messages
    5. Test: enviar WA → verificar lead en crm_leads

═════════════════════════════════════════════════════════════
WORKFLOWS N8N QUE NECESITAN ACTIVACIÓN MANUAL
═════════════════════════════════════════════════════════════

Están creados pero necesitan 1 paso en n8n UI:

1. WF-MCP-ANALISIS-FINANCIERO-v1 (id=J9F5paaLfbbHQ09y)
   → Abrir → Nodo "Get Bookings" → Agregar creds Supabase → Activar

2. WF-HERMES-GUARDIAN-v1 (id=wT4AD9VhFZc0DfGH)  
   → Abrir → Nodo "01_HERMES_SCHEDULE" → Cambiar a cada 60 min → Activar

3. ALIUN — Conversion Leads (id=QK1ZF7Ix5UJWfNYV)
   → Abrir → Agregar creds Supabase + Meta CAPI → Pixel 1197179654562182 → Activar

═════════════════════════════════════════════════════════════
FLUJO E2E COMPLETO (13 PASOS SOP) — VERIFICACIÓN
═════════════════════════════════════════════════════════════

Para cada paso, verifica con un curl test:

PASO 1: Lead entra por WhatsApp
  → /webhook/aliun-wa-incoming → /webhook/aliun-lead → crm_leads
  TEST: curl POST /webhook/aliun-lead con payload de test

PASO 2: Agente recibe contexto
  → OpenClaw/Hermes Commercial lee lead + contexto hotel
  TEST: MCP tool buscar_hoteles con destino

PASO 3: Búsqueda de hoteles
  → MCP tool buscar_hoteles → /webhook/mcp-buscar-hoteles
  TEST: curl POST /webhook/mcp-buscar-hoteles

PASO 4: Consultar disponibilidad
  → MCP tool consultar_disponibilidad → Supabase RPC
  TEST: curl POST /webhook/horizons-booking-api action=GET_ROOMS

PASO 5: Cotización
  → MCP tool calcular_cotizacion → Supabase RPC
  TEST: curl POST /webhook/horizons-booking-api action=QUOTE

PASO 6: Cotización PDF + Landing
  → MCP tool generar_cotizacion_pdf → /webhook/aliun-cotizacion
  → Retorna landing_url
  TEST: curl POST /webhook/aliun-cotizacion → DEBE retornar JSON con landing_url

PASO 7: Greenlight Gate (Director aprueba)
  → Notificación Telegram al Director → ✅/❌
  TEST: verificar WF-SALES-FULFILLMENT-HANDLER-v2 envía Telegram

PASO 8: Confirmar reserva
  → /webhook/horizons-booking-api action=CREATE_BOOKING
  TEST: curl POST → DEBE retornar booking_reference ALN-XXXXXX

PASO 9: Validar comprobante de pago
  → MCP tool validar_comprobante → /webhook/validar-comprobante
  TEST: curl POST /webhook/validar-comprobante

PASO 10: Aprobar depósito
  → /webhook/aliun-deposito-aprobado
  TEST: curl POST /webhook/aliun-deposito-aprobado

PASO 11: Generar voucher PDF
  → /webhook/aliun-voucher → Gotenberg → PDF → Storage
  TEST: curl POST /webhook/aliun-voucher

PASO 12: Confirmación + Estado de cuenta
  → /webhook/aliun-confirmacion → PDFMonkey → PDF → Email
  TEST: curl POST /webhook/aliun-confirmacion

PASO 13: Notificación final
  → WF-SALES-FULFILLMENT-HANDLER-v2 → Telegram Director + Email cliente
  TEST: verificar que llega notificación

═════════════════════════════════════════════════════════════
REGLAS INVARIABLES
═════════════════════════════════════════════════════════════

1. NUNCA inventar precios — siempre de Supabase RPC o tarifa real
2. NUNCA confirmar sin Director (Greenlight Gate)
3. NUNCA decir "confirmada" con solo depósito — hasta voucher generado
4. NUNCA crear urgencia sin dato real de stock
5. Si un endpoint falla → mostrar error real, NUNCA placeholder verde
6. Todos los webhooks deben retornar JSON con status explícito
7. Supabase RPC params deben coincidir EXACTAMENTE con firma SQL
8. Proyecto es ESM ("type": "module") — imports con .js extension
9. 3 bugs recurrentes eliminados: template literals sin backticks, || faltantes, CommonJS→ESM

═════════════════════════════════════════════════════════════
CREDENCIALES Y ENDPOINTS
═════════════════════════════════════════════════════════════

n8n: https://n8n-n8n.xaruuo.easypanel.host
Supabase URL: https://qxlmnsnxwlmfhspjehbh.supabase.co
Supabase Anon Key: En EasyPanel env vars del MCP
MCP Server: https://n8n-atlas-sales-mcp.xaruuo.easypanel.host/mcp
MCP Repo: aliuntravelsrl-hash/atlas-sales-mcp
Frontend Repo: aliuntravelsrl-hash/atlas-booking-frontend-v2 (PRIVADO)
API Toolbox: aliuntravelsrl-hash/atlas-api-toolbox
Meta Business ID: 566853080395362
Meta Pixel: 1197179654562182
Meta Ad Account: 23849225440650509
WhatsApp Number: 849-583-3500 (pendiente verificación)

═════════════════════════════════════════════════════════════
CRITERIO DE ÉXITO
═════════════════════════════════════════════════════════════

SOP E2E está CERRADO cuando:
1. ✅ Los 13 pasos pasan test curl individual
2. ✅ Booking API retorna ALN-XXXXXX sin errores
3. ✅ Cotización retorna landing_url + pdf_url
4. ✅ Voucher se genera después de pago aprobado
5. ✅ Confirmación + estado de cuenta se envía por email
6. ✅ Mission Control muestra datos reales (no mock)
7. ✅ paidNoVoucher > 0 muestra alerta SEV1 roja
8. ✅ Guardian monitoriza cada 60 min
9. ✅ Conversion Leads envía CAPI events a Meta

Al final: ejecutar test E2E completo desde WhatsApp → voucher → notificación.
Si los 13 pasos pasan = SOP CERRADO.
