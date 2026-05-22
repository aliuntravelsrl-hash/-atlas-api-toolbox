# PROMPT ANTIGRAVITY — Cableado Real Mission Control + Booking → Voucher

## CONTEXTO
Aldo quiere Mission Control con DATOS REALES, no dashboard decorativo. Los webhooks n8n YA EXISTEN y están activos. El MCP tiene 13 tools cableadas. Solo falta conectar el frontend a los endpoints correctos.

---

## MAPA COMPLETO DE ENDPOINTS (FUENTE DE VERDAD)

### n8n Webhooks ACTIVOS ahora mismo
```
BASE: https://n8n-n8n.xaruuo.easypanel.host

🟢 POST /webhook/aliun-cotizacion          → Cotización PDF + Landing
🟢 GET  /webhook/cotizacion-landing         → Landing page cotización
🟢 POST /webhook/aliun-voucher             → Voucher PDF (Gotenberg)
🟢 POST /webhook/aliun-deposito-aprobado   → Depósito aprobación
🟢 POST /webhook/validar-comprobante        → Validar comprobante pago
🟢 POST /webhook/aliun-confirmacion         → Confirmación + estado cuenta
🟢 POST /webhook/horizons-booking-api       → Booking API (Horizons)
🟢 POST /webhook/registrar-interes          → Registrar interés/depósito
🟢 POST /webhook/aliun-lead                 → Captura leads
🟢 POST /webhook/sales-fulfillment-notify   → Fulfillment notificación
🟢 POST /webhook/mcp-buscar-hoteles         → Buscar hoteles
🟢 POST /webhook/mcp-obtener-galeria-hotel  → Galería hotel
🟢 POST /webhook/mcp-generar-post-creativo  → Post creativo marketing
🟢 POST /webhook/consultar-perfil-hotel     → Perfil hotel completo
🟢 GET  /webhook/mcp-health                 → Health check MCP (NUEVO 🆕)
🟢 POST /webhook/mcp-analisis-financiero     → Métricas financieras (NUEVO 🆕)
🟢 POST /webhook/aliun-wa-incoming          → WhatsApp incoming (NUEVO 🆕)
```

### Workflows creados pero REQUIEREN configuración en n8n UI
```
⚠️ WF-MCP-ANALISIS-FINANCIERO-v1 (id=J9F5paaLfbbHQ09y)
   → Activar en n8n UI: agregar credenciales Supabase al nodo "Get Bookings"

⚠️ WF-HERMES-GUARDIAN-v1 (id=wT4AD9VhFZc0DfGH)
   → Activar en n8n UI: reparar schedule trigger ("Invalid interval")

⚠️ ALIUN — Conversion Leads (CRM → Meta CAPI) (id=QK1ZF7Ix5UJWfNYV)
   → Activar en n8n UI: agregar credenciales Supabase + HTTP Request a Meta CAPI
```

---

## TAREA 1: MissionControlLive.jsx — DATOS REALES

### Reemplazar todos los heartbeats/mock con consultas reales:

```jsx
import { supabase } from '../../lib/supabaseClient';

// === SYSTEM STATUS (cada 30s) ===
// Ping n8n MCP Health proxy
const fetchSystemStatus = async () => {
  try {
    const res = await fetch('https://n8n-n8n.xaruuo.easypanel.host/webhook/mcp-health');
    const data = await res.json();
    return {
      mcp: data.status === 'ok' ? '🟢' : '🔴',
      mcpVersion: data.version || '—',
      mcpTools: data.tools || 0,
      supabase: data.supabase === 'connected' ? '🟢' : '🔴',
      n8n: '🟢', // si llegamos hasta aquí, n8n está up
      checkedAt: data.checked_at
    };
  } catch {
    return { mcp: '🔴', n8n: '🔴', supabase: '🔴' };
  }
};

// === BOOKING STATS (cada 60s) ===
// Direct Supabase query — no API intermedia
const fetchBookingStats = async () => {
  const { count: total } = await supabase
    .from('bookings')
    .select('*', { count: 'exact', head: true });

  const { count: paid } = await supabase
    .from('bookings')
    .select('*', { count: 'exact', head: true })
    .eq('payment_status', 'paid');

  const { count: pending } = await supabase
    .from('bookings')
    .select('*', { count: 'exact', head: true })
    .eq('payment_status', 'pending');

  const { count: confirmed } = await supabase
    .from('bookings')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'confirmed');

  const { count: cancelled } = await supabase
    .from('bookings')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'cancelled');

  return { total, paid, pending, confirmed, cancelled };
};

// === PAID NO VOUCHER — ALERTA CRÍTICA ===
const fetchPaidNoVoucher = async () => {
  const { data } = await supabase
    .from('bookings')
    .select('id, booking_reference, total_amount, currency, created_at')
    .eq('payment_status', 'paid')
    .is('voucher_code', null)
    .is('voucher_id', null);

  return data || []; // Si length > 0 → BANNER ROJO 🔴
};
```

### UI del banner de alerta:
```jsx
{paidNoVoucher.length > 0 && (
  <div className="bg-red-900/50 border border-red-500 rounded-lg p-3 animate-pulse">
    <span className="text-red-400 font-bold">
      ⚠️ {paidNoVoucher.length} RESERVA(S) PAGADA(S) SIN VOUCHER
    </span>
    {paidNoVoucher.map(b => (
      <div key={b.id} className="text-sm text-red-300 mt-1">
        {b.booking_reference} — {b.currency} {b.total_amount} — {b.created_at}
      </div>
    ))}
  </div>
)}
```

### Logging real:
```jsx
// Reemplazar logs mock con transacciones reales de bookings
const [recentActivity, setRecentActivity] = useState([]);

const fetchRecentActivity = async () => {
  const { data } = await supabase
    .from('bookings')
    .select('booking_reference, status, payment_status, created_at, total_amount, currency')
    .order('created_at', { ascending: false })
    .limit(10);
  setRecentActivity(data || []);
};
```

---

## TAREA 2: Booking Flow → Voucher — CABLEADO END-TO-END

### Flujo completo (cada paso con su endpoint):

```
PASO 1: Cliente reserva en frontend
  → POST /webhook/horizons-booking-api
  → Crea booking en Supabase → retorna ALN-XXXXXX
  → Frontend redirige a /booking/confirm

PASO 2: Cliente sube comprobante de pago
  → POST /webhook/validar-comprobante
  → n8n valida → actualiza payment_status='pending_review'
  → Notifica a Hermes por Telegram

PASO 3: Operador aprueba depósito
  → POST /webhook/aliun-deposito-aprobado
  → n8n actualiza payment_status='paid'
  → Dispara automáticamente:

PASO 4: Voucher generation (AUTO cuando pago aprobado)
  → POST /webhook/aliun-voucher
  → Gotenberg renderiza PDF → sube a storage
  → Actualiza booking: voucher_code + voucher_id (landing_url)
  → Notifica a cliente + Hermes por Telegram

PASO 5: Si voucher falla → Guardian detecta
  → Playbook: detect_missing_voucher
  → payment_status='paid' AND voucher_code IS NULL AND voucher_id IS NULL
  → Auto-reintenta 1 vez → si falla → escala a Director
```

### Conexión ReviewBooking.jsx → Crear reserva:
```jsx
// En ReviewBooking.jsx, handleConfirm:
const handleConfirm = async () => {
  const response = await fetch(
    'https://n8n-n8n.xaruuo.easypanel.host/webhook/horizons-booking-api',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'CREATE_BOOKING',
        hotel_id: booking.hotelId,
        check_in: booking.checkIn,
        check_out: booking.checkOut,
        guests: booking.guests,
        rooms: booking.selectedRooms,
        guest_details: booking.guestDetails,
        total_amount: booking.totalAmount,
        currency: booking.currency,
        payment_method: booking.paymentMethod,
        source: 'web'
      })
    }
  );
  const result = await response.json();
  // result.booking_reference = "ALN-XXXXXX"
  navigate(`/booking/confirm?ref=${result.booking_reference}`);
};
```

---

## TAREA 3: Configurar 3 Workflows en n8n UI

Están creados pero necesitan credenciales:

### WF-MCP-ANALISIS-FINANCIERO-v1 (id=J9F5paaLfbbHQ09y)
1. Abrir en n8n
2. Nodo "Get Bookings" → agregar credenciales Supabase
3. Activar

### WF-HERMES-GUARDIAN-v1 (id=wT4AD9VhFZc0DfGH)
1. Abrir en n8n
2. Nodo "01_HERMES_SCHEDULE" → cambiar a cada 60 minutos (el trigger actual tiene "Invalid interval")
3. Verificar que los nodos HTTP Request apuntan a Supabase correcto
4. Activar

### ALIUN — Conversion Leads (id=QK1ZF7Ix5UJWfNYV)
1. Abrir en n8n
2. Agregar credenciales Supabase al nodo de consulta
3. Agregar ACCESS_TOKEN de Meta CAPI al nodo HTTP
4. Configurar Pixel ID: 1197179654562182
5. Activar

---

## REGLAS
- NUNCA datos mock en Mission Control — todo desde Supabase o n8n
- Si un endpoint falla → mostrar 🔴, NUNCA placeholder verde
- paidNoVoucher > 0 = SIEMPRE banner rojo visible
- Los logs de actividad deben ser transacciones reales de bookings
- Build DEBE compilar sin warnings: `npm run build`
- Probar localmente con `npm run dev` antes de deploy
- Deploy quirúrgico: build local → SCP a Hostinger public_html

## SUPABASE
- Anon Key: ya configurada en supabaseClient.js
- Tabla principal: `bookings`
- Campos clave: booking_reference, status, payment_status, voucher_code, voucher_id, total_amount, currency, created_at
- Alerta: payment_status='paid' AND voucher_code IS NULL AND voucher_id IS NULL
