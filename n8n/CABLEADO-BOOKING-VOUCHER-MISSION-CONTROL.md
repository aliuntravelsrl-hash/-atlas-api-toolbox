# ALIUN — Cableado Completo: Booking → Voucher → Mission Control

## Arquitectura de Flujo

```
Cliente (Web/WA)
      │
      ▼
┌─────────────────────────────────────────────────┐
│  FRONTEND (aliuntravelsrl.com)                  │
│  HotelBookingForm → BookingContext              │
│  /booking/rooms → /booking/guests → /booking/review → /booking/confirm
│  ALN-XXXXXX generado                            │
└──────────────────────┬──────────────────────────┘
                       │ POST
                       ▼
┌─────────────────────────────────────────────────┐
│  N8N — Webhook Orquestador                      │
│  /webhook/aliun-cotizacion                      │
│  /webhook/wf-registrar-deposito                 │
│  /webhook/wf-deposito-aprobacion-v1/validate     │
│  /webhook/mcp-analisis-financiero               │
│  /webhook/mcp-generar-post-creativo             │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  SUPABASE (CRM + Bookings)                      │
│  bookings: { status, payment_status, voucher_id }│
│  crm_leads: { stage, meta_lead_id }             │
│  crm_activities: INSERT ONLY                    │
│  crm_deals: { amount, stage }                   │
│  crm_capi_logs: INSERT ONLY                     │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  HERMES TRANSLATOR (Voucher Delivery + PDF)      │
│  MCP Tool: generar_cotizacion_pdf               │
│  → landing_url (branded page + PDF + WA button) │
│  MCP Tool: registrar_deposito                   │
│  → Estado de Cuenta PDF                         │
│  MCP Tool: consultar_reserva                    │
│  → Status + voucher_id check                    │
│  MCP Tool: validar_comprobante                  │
│  → Depósito approval pipeline                   │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────┐
│  MISSION CONTROL LIVE (Horizons)                │
│  MissionControlLive.jsx                         │
│  → Reemplazar heartbeats por datos REALES       │
└─────────────────────────────────────────────────┘
```

---

## 1. N8N Webhooks — Endpoints Activos

### 1a. `/webhook/aliun-cotizacion` (Cotización + PDF + Landing)
**Método:** POST  
**Payload IN:**
```json
{
  "slug": "occidental-caribe",
  "nombre": "Juan Pérez",
  "email": "juan@example.com",
  "check_in": "2026-06-15",
  "check_out": "2026-06-20",
  "habitacion": "Deluxe Sea View",
  "regimen": "Todo Incluido",
  "pasajeros": 2,
  "precio_total": 1250.00,
  "moneda": "USD"
}
```
**Payload OUT:**
```json
{
  "landing_url": "https://aliuntravelsrl.com/cotizacion/ABC123",
  "pdf_url": "https://aliuntravelsrl.com/cotizacion/ABC123/pdf",
  "id_cotizacion": "ABC123"
}
```

**Nodos n8n requeridos:**
1. Webhook (POST)
2. Supabase: INSERT cotización en tabla `cotizaciones`
3. HTTP Request: Generar PDF (endpoint de renderizado)
4. HTTP Request: Generar landing page HTML
5. Respond to Webhook: `{ landing_url, pdf_url, id_cotizacion }`

### 1b. `/webhook/wf-registrar-deposito` (Registro de Depósito)
**Método:** POST  
**Payload IN:**
```json
{
  "booking_reference": "ALN-12345",
  "monto_deposito": 500.00,
  "email_cliente": "juan@example.com",
  "metodo_pago": "transferencia",
  "notas": "Banco Popular RD"
}
```
**Payload OUT:**
```json
{
  "status": "registered",
  "deposit_id": "dep_xxx",
  "account_statement_url": "https://..."
}
```

### 1c. `/webhook/wf-deposito-aprobacion-v1/validate` (Validar Comprobante)
**Método:** POST  
**Payload IN:**
```json
{
  "booking_reference": "ALN-12345",
  "comprobante_url": "https://...",
  "monto_declarado": 500.00
}
```

### 1d. `/webhook/mcp-analisis-financiero` (Análisis Financiero)
**Método:** POST  
**Para:** Dashboard de finanzas en Mission Control

### 1e. `/webhook/mcp-generar-post-creativo` (Marketing)
**Método:** POST  
**Para:** Generar copies creativos para redes

---

## 2. MCP Tools — 13 Herramientas Registradas

| Tool | Webhook n8n | Función |
|---|---|---|
| `buscar_hoteles` | Supabase directo | Busca por slug/destino |
| `consultar_disponibilidad` | Supabase directo | Check realtime |
| `calcular_cotizacion` | Supabase directo | Precio dinámico |
| `calcular_precio_paquete` | Supabase directo | Paquete combinado |
| `generar_cotizacion_pdf` | `/webhook/aliun-cotizacion` | **LANDING + PDF** |
| `registrar_deposito` | `/webhook/wf-registrar-deposito` | **VOUCHER TRIGGER** |
| `validar_comprobante` | `/webhook/wf-deposito-aprobacion-v1/validate` | Approval pipeline |
| `consultar_reserva` | Supabase directo | Status ALN-XXXXX |
| `buscar_ofertas_marketing` | Supabase directo | Ofertas activas |
| `generar_post_creativo` | `/webhook/mcp-generar-post-creativo` | Copies marketing |
| `analisis_financiero` | `/webhook/mcp-analisis-financiero` | Dashboard finanzas |
| `obtener_galeria_hotel` | Supabase directo | Fotos del hotel |
| `validar_ocupacion_habitacion` | Supabase directo | Capacidad room |

---

## 3. Voucher Delivery Flow — Paso a Paso

```
Reserva creada (ALN-XXXXX)
       │
       ▼
status = 'confirmed', payment_status = 'pending'
voucher_id = NULL
       │
       ▼
Cliente realiza depósito
       │
       ▼
registrar_deposito (MCP → n8n)
       │
       ▼
n8n: UPDATE bookings SET payment_status='partial' o 'paid'
       │
       ▼
IF payment_status == 'paid'
       │
       ▼
Hermes Translator: generar_cotizacion_pdf (ahora funciona como voucher)
       │
       ├── landing_url → branded page con voucher
       ├── pdf_url → descarga directa
       └── n8n: UPDATE bookings SET voucher_id = landing_url
       │
       ▼
Notificación WhatsApp/Email al cliente
       │
       ▼
Mission Control: muestra status REAL
```

**⚠️ NOTA:** `generar_cotizacion_pdf` actualmente genera cotización. Para vouchers, necesita un workflow adicional que:
1. Use la landing page pero con diseño de voucher (logo hotel, confirmation code, fechas, datos huésped)
2. Se triggere cuando `payment_status == 'paid'`
3. Auto-notifique al cliente vía WA/Email

---

## 4. Playbooks de Voucher (Auto-detección)

### detect_missing_voucher
```json
{
  "trigger": "booking.status == 'paid' AND booking.voucher_id IS NULL AND age_minutes > 60",
  "steps": [
    "load_booking_from_supabase(booking_id)",
    "check_provider_locator(booking_id)",
    "if locator_exists -> trigger_voucher_generation_workflow(booking_id)",
    "if locator_missing -> flag_for_manual_review(booking_id)",
    "notify_if_flagged('missing_voucher', booking_id)"
  ],
  "safe_to_autoexecute": true,
  "severity": "high",
  "escalation_channel": "telegram_ops"
}
```

### voucher_not_generated (Paperclip OTA)
```json
{
  "trigger": "payment_status == 'paid' AND fulfillment_status == 'confirmed' AND voucher == null",
  "steps": [
    "log_incident('voucher_not_generated', booking_id)",
    "trigger_voucher_generation_workflow(booking_id)",
    "wait(60)",
    "verify_resolution(booking_id)",
    "notify_if_flagged('missing_voucher_escalation', booking_id)"
  ],
  "safe_to_autoexecute": true,
  "max_auto_retries": 1
}
```

---

## 5. Mission Control Live — Reemplazar Heartbeats

### Endpoint: `GET /api/mcp/health`
```json
{
  "status": "ok",
  "version": "1.3.1",
  "active_sessions": 0,
  "tools": 13,
  "supabase": "connected"
}
```

### Endpoint: `GET /api/bookings/stats` (n8n o Supabase directo)
```json
{
  "total": 42,
  "confirmed": 28,
  "pending_payment": 8,
  "paid_no_voucher": 3,
  "completed": 3,
  "revenue_today": 4500.00,
  "currency": "USD"
}
```

### Mapeo para MissionControlLive.jsx

**Reemplazar esto:**
```jsx
// SIMULADO
const [heartbeat, setHeartbeat] = useState(null);
useEffect(() => {
  const timer = setInterval(() => setHeartbeat(Date.now()), 5000);
  return () => clearInterval(timer);
}, []);
```

**Con esto:**
```jsx
// REAL
const [systemStatus, setSystemStatus] = useState(null);
const [bookingStats, setBookingStats] = useState(null);

// MCP Health — cada 30s
useEffect(() => {
  const fetchHealth = async () => {
    try {
      const res = await fetch('https://mcp.aliuntravelsrl.com/health');
      setSystemStatus(await res.json());
    } catch { setSystemStatus({ status: 'error' }); }
  };
  fetchHealth();
  const timer = setInterval(fetchHealth, 30000);
  return () => clearInterval(timer);
}, []);

// Booking Stats — cada 60s
useEffect(() => {
  const fetchStats = async () => {
    try {
      const res = await fetch('https://mcp.aliuntravelsrl.com/api/bookings/stats');
      setBookingStats(await res.json());
    } catch { setBookingStats(null); }
  };
  fetchStats();
  const timer = setInterval(fetchStats, 60000);
  return () => clearInterval(timer);
}, []);
```

### Cards del Mission Control — Datos Reales

```jsx
// Hermes Translator — Voucher Delivery
<HermesCard
  role="Voucher Delivery"
  status={systemStatus?.status}  // "ok" | "error"
  version={systemStatus?.version}  // "1.3.1"
  activeSessions={systemStatus?.active_sessions}
  toolsAvailable={systemStatus?.tools}
  supabaseConnected={systemStatus?.supabase === 'connected'}
  paidNoVoucher={bookingStats?.paid_no_voucher}  // CRITICAL: si > 0, alertar
/>

// Booking Pipeline
<PipelineCard
  confirmed={bookingStats?.confirmed}
  pendingPayment={bookingStats?.pending_payment}
  paidNoVoucher={bookingStats?.paid_no_voucher}  // necesita voucher generation
  completed={bookingStats?.completed}
  revenueToday={bookingStats?.revenue_today}
  currency={bookingStats?.currency}
/>

// Finance
<FinanceCard
  revenueToday={bookingStats?.revenue_today}
  currency={bookingStats?.currency}
  depositsPending={bookingStats?.deposits_pending}
/>
```

---

## 6. Tabla Supabase `bookings` — Campos Clave

```sql
bookings (
  id              UUID PK,
  booking_reference TEXT UNIQUE,     -- ALN-XXXXX
  lead_guest_name  TEXT,
  hotel_id         UUID REFERENCES hotels(id),
  status           TEXT DEFAULT 'confirmed',  -- confirmed | cancelled | completed
  check_in         DATE,
  check_out        DATE,
  total_amount     NUMERIC,
  currency         TEXT DEFAULT 'USD',
  payment_status   TEXT DEFAULT 'pending',  -- pending | partial | paid
  deposit_amount   NUMERIC DEFAULT 0,
  voucher_id       TEXT,             -- landing_url del voucher (NULL = no generado)
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
)
```

**Voucher generado cuando:** `payment_status = 'paid'` → `voucher_id` se llena con `landing_url`

---

## 7. Próximos Pasos

1. **Crear workflow n8n `/webhook/aliun-cotizacion`** — genera landing + PDF
2. **Crear endpoint `/api/bookings/stats`** — en n8n o como Supabase RPC
3. **Reemplazar heartbeats en MissionControlLive.jsx** — conectar a datos reales
4. **Crear workflow n8n de voucher auto-generation** — trigger cuando payment_status cambia a 'paid'
5. **Conectar WhatsApp Bot** — notificar voucher al cliente vía WA cuando se genera
