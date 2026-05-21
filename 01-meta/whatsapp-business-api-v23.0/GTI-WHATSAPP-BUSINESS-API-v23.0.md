---
title: GTI · WhatsApp Business Cloud API v23.0
version: 1.0.0
date: 2026-05-20
source: https://github.com/facebook/openapi
spec_file: business-messaging-api_v23.0.yaml (1,092,981 bytes, 30,597 lines)
status: HERRAMIENTA #1 — Referencia Oficial Meta
owner: ALIUN TRAVEL SRL
classification: OPERATIVO
---

# GTI · WhatsApp Business Cloud API v23.0

> Referencia cognitiva completa del spec oficial Meta OpenAPI para WhatsApp Business API.
> Fuente única de verdad para desarrollo de integraciones ALIUN.
> Última actualización del spec: abril 2026.

---

## 1. Información General

| Campo | Valor |
|---|---|
| **Título** | Meta Graph API — WhatsApp Business Messaging |
| **Versión API** | v23.0 |
| **Servidor** | `https://graph.facebook.com` |
| **Autenticación** | Bearer Token (OAuth 2.0) |
| **Licencia spec** | MIT |
| **Términos uso API** | https://developers.facebook.com/terms |
| **Contacto** | Meta Business Platform Team |
| **Soporte** | https://developers.facebook.com/support |

### URL Base

```
https://graph.facebook.com/{Version}/{Resource-ID}
```

- `{Version}` = `v23.0` (o la versión activa)
- `{Resource-ID}` = Business-ID, Phone-Number-ID, WABA-ID, etc.

### Autenticación

```
Authorization: Bearer {ACCESS_TOKEN}
```

Un solo esquema: `bearerAuth`. El token se obtiene via Meta App Dashboard o Multi-Partner Solution.

---

## 2. Catálogo de Endpoints (113 total)

### 2.1 💬 Mensajería (Core — 8 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 20 | **POST** | `/{Phone-Number-ID}/messages` | **Enviar mensaje** (texto, imagen, video, audio, documento, ubicación, contacto, template, interactivo, reacción, sticker) |
| 25 | **POST** | `/{Phone-Number-ID}/messages_encrypted` | Enviar mensaje encriptado |
| 19 | **POST** | `/{Phone-Number-ID}/media` | Subir media (imagen, video, audio, documento) |
| 55 | **GET** | `/{Media-ID}` | Obtener URL de descarga de media |
| 56 | **DELETE** | `/{Media-ID}` | Eliminar media |
| 57 | **GET** | `/{Media-URL}` | Descargar media |
| 31 | **GET** | `/{Phone-Number-ID}/message_history` | Obtener historial de mensajes |
| 58 | **GET** | `/{Message-History-ID}/events` | Obtener eventos de historial |

### 2.2 📋 Templates (6 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 102 | **GET** | `/{TEMPLATE_ID}` | Obtener template por ID |
| 103 | **POST** | `/{TEMPLATE_ID}` | Editar template |
| 104 | **GET** | `/{WABA-ID}/message_templates` | Listar templates por nombre |
| 105 | **POST** | `/{WABA-ID}/message_templates` | Crear template (auth OTP, marketing, etc.) |
| 106 | **DELETE** | `/{WABA-ID}/message_templates` | Eliminar template por nombre |

### 2.3 📢 Marketing (3 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 18 | **POST** | `/{Phone-Number-ID}/marketing_messages` | **Enviar mensaje marketing** (template con políticas de producto) |
| 94 | **GET** | `/{WABA-ID}/schedules` | Obtener programaciones de envío |
| 95 | **POST** | `/{WABA-ID}/schedules` | Crear programación de envío |

### 2.4 🔄 Flows (8 endpoints) ⭐ NUEVO

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 79 | **GET** | `/{WABA-ID}/flows` | Listar Flows |
| 80 | **POST** | `/{WABA-ID}/flows` | **Crear Flow** (multipart/form-data) |
| 81 | **POST** | `/{WABA-ID}/migrate_flows` | Migrar Flows |
| 82 | **GET** | `/{Flow-ID}` | Obtener Flow |
| 83 | **POST** | `/{Flow-ID}` | Actualizar metadata de Flow |
| 84 | **DELETE** | `/{Flow-ID}` | Eliminar Flow |
| 85 | **GET** | `/{Flow-ID}/assets` | Listar assets (obtener Flow JSON URL) |
| 86 | **POST** | `/{Flow-ID}/assets` | **Actualizar Flow JSON** (multipart/form-data) |
| 87 | **POST** | `/{Flow-ID}/publish` | **Publicar Flow** (poner en producción) |
| 88 | **POST** | `/{Flow-ID}/deprecate` | Deprecar Flow |

### 2.5 🔗 Webhooks (2 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 113 | **POST** | `/whatsapp/webhooks` | **Recibir mensajes y eventos** (incoming messages, status updates, group events) |
| 99 | **GET** | `/{WABA-ID}/subscribed_apps` | Ver suscripciones webhook de un WABA |
| 100 | **POST** | `/{WABA-ID}/subscribed_apps` | Suscribir app a webhooks de un WABA |
| 101 | **DELETE** | `/{WABA-ID}/subscribed_apps` | Desuscribir app de webhooks |

### 2.6 📱 Phone Numbers (12 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 28 | **GET** | `/{Phone-Number-ID}` | Info del número de teléfono |
| 29 | **POST** | `/{Phone-Number-ID}` | Actualizar configuración del número |
| 30 | **POST** | `/{Phone-Number-ID}/deregister` | Desregistrar número |
| 32 | **POST** | `/{Phone-Number-ID}/register` | Registrar número |
| 33 | **POST** | `/{Phone-Number-ID}/request_code` | Solicitar código de verificación |
| 34 | **GET** | `/{Phone-Number-ID}/settings` | Obtener settings del número |
| 35 | **POST** | `/{Phone-Number-ID}/settings` | Actualizar settings del número |
| 36 | **POST** | `/{Phone-Number-ID}/verify_code` | Verificar código OTP |
| 92 | **GET** | `/{WABA-ID}/phone_numbers` | Listar números del WABA |
| 93 | **POST** | `/{WABA-ID}/phone_numbers` | Crear número para el WABA |

### 2.7 🏢 Business Account (8 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 5 | **GET** | `/{Business-ID}` | Info del portfolio de negocio |
| 7 | **GET** | `/{Business-ID}/client_whatsapp_business_accounts` | WABAs de clientes |
| 9 | **GET** | `/{Business-ID}/owned_whatsapp_business_accounts` | WABAs propios |
| 78 | **GET** | `/{Business-ID}/extendedcredits` | Líneas de crédito |
| 108 | **GET** | `/{WABA-ID}` | Detalles del WABA |
| 109 | **POST** | `/{WABA-ID}` | Actualizar WABA |
| 107 | **GET** | `/{WABA-ID}/activities` | Actividades del WABA |
| 74-76 | **GET/POST/DELETE** | `/{WABA-ID}/assigned_users` | Gestión de usuarios asignados |

### 2.8 👥 Groups (8 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 16 | **POST** | `/{Phone-Number-ID}/groups` | Crear grupo |
| 17 | **GET** | `/{Phone-Number-ID}/groups` | Listar grupos activos |
| 45 | **POST** | `/{group_id}/invite_link` | Crear link de invitación |
| 46 | **DELETE** | `/{group_id}/invite_link` | Eliminar link de invitación |
| 47 | **GET** | `/{group_id}/join_requests` | Ver solicitudes de ingreso |
| 48 | **POST** | `/{group_id}/join_requests` | Aprobar solicitudes |
| 49 | **DELETE** | `/{group_id}/join_requests` | Rechazar solicitudes |
| 50 | **POST** | `/{group_id}/participants` | Agregar participantes |
| 51 | **DELETE** | `/{group_id}/participants` | Remover participantes |
| 52 | **GET** | `/{group_id}` | Info del grupo |
| 53 | **DELETE** | `/{group_id}` | Eliminar grupo |
| 54 | **POST** | `/{group_id}` | Actualizar settings del grupo |

### 2.9 🛡️ Perfil y Compliance (8 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 39 | **GET** | `/{Phone-Number-ID}/whatsapp_business_profile` | Obtener perfil business |
| 40 | **POST** | `/{Phone-Number-ID}/whatsapp_business_profile` | Actualizar perfil business |
| 41 | **GET** | `/{Phone-Number-ID}/whatsapp_commerce_settings` | Obtener settings commerce |
| 42 | **POST** | `/{Phone-Number-ID}/whatsapp_commerce_settings` | Configurar commerce (catálogo visible, carrito) |
| 43 | **GET** | `/{Phone-Number-ID}/business_compliance_info` | Info de compliance |
| 44 | **POST** | `/{Phone-Number-ID}/business_compliance_info` | Actualizar compliance |
| 26 | **GET** | `/{Phone-Number-ID}/official_business_account` | Estado de cuenta oficial |
| 27 | **POST** | `/{Phone-Number-ID}/official_business_account` | Solicitar cuenta oficial |

### 2.10 🔐 Seguridad y Encriptación (4 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 11 | **GET** | `/{Phone-Number-ID}/block_users` | Ver usuarios bloqueados |
| 12 | **POST** | `/{Phone-Number-ID}/block_users` | Bloquear usuarios |
| 13 | **DELETE** | `/{Phone-Number-ID}/block_users` | Desbloquear usuarios |
| 37 | **GET** | `/{Phone-Number-ID}/whatsapp_business_encryption` | Obtener clave pública de encriptación |
| 38 | **POST** | `/{Phone-Number-ID}/whatsapp_business_encryption` | Establecer clave pública |

### 2.11 📞 Llamadas (3 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 14 | **GET** | `/{Phone-Number-ID}/call_permissions` | Verificar permisos de llamada |
| 15 | **POST** | `/{Phone-Number-ID}/calls` | Gestionar llamadas (iniciar/terminar) |

### 2.12 🤖 Automatización Conversacional (1 endpoint)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 77 | **POST** | `/{Phone-Number-ID}/conversational_automation` | Configurar mensajes de bienvenida, ice breakers, y comandos de bot |

### 2.13 🧩 Multi-Partner Solutions (10 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 2 | **POST** | `/{Application-ID}/whatsapp_business_solution` | Crear solución multi-partner |
| 3 | **GET** | `/{Application-ID}/whatsapp_business_solutions` | Listar soluciones |
| 65 | **GET** | `/{Solution-ID}/access_token` | Obtener access token de solución |
| 67 | **POST** | `/{Solution-ID}/accept` | Aceptar invitación |
| 70 | **POST** | `/{Solution-ID}/reject` | Rechazar solicitud |
| 66 | **POST** | `/{Solution-ID}/accept_deactivation_request` | Aceptar desactivación |
| 69 | **POST** | `/{Solution-ID}/reject_deactivation_request` | Rechazar desactivación |
| 71 | **POST** | `/{Solution-ID}/send_deactivation_request` | Enviar solicitud de desactivación |
| 98 | **GET** | `/{WABA-ID}/solutions` | Listar soluciones de un WABA |

### 2.14 📲 Pre-Verified Numbers (5 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 6 | **GET** | `/{Business-ID}/preverified_numbers` | Listar números pre-verificados |
| 60 | **GET** | `/{Pre-Verified-Phone-Number-ID}` | Detalle de número pre-verificado |
| 61 | **DELETE** | `/{Pre-Verified-Phone-Number-ID}` | Eliminar número pre-verificado |
| 63 | **POST** | `/{Pre-Verified-Phone-Number-ID}/request_code` | Solicitar código de verificación |
| 64 | **POST** | `/{Pre-Verified-Phone-Number-ID}/verify_code` | Verificar código OTP |

### 2.15 📟 QR Codes (4 endpoints)

| # | Método | Endpoint | Descripción |
|---|---|---|---|
| 21 | **GET** | `/{Phone-Number-ID}/message_qrdls` | Listar todos los QR codes |
| 22 | **POST** | `/{Phone-Number-ID}/message_qrdls` | Crear o actualizar QR code |
| 23 | **GET** | `/{Phone-Number-ID}/message_qrdls/{QR-Code-ID}` | Obtener QR code individual |
| 24 | **DELETE** | `/{Phone-Number-ID}/message_qrdls/{QR-Code-ID}` | Eliminar QR code |

---

## 3. Schemas Clave (369 totales — los esenciales)

### 3.1 MessageRequest — Enviar Mensaje

```json
{
  "messaging_product": "whatsapp",          // SIEMPRE "whatsapp"
  "recipient_type": "individual|group",     // Tipo de destinatario
  "to": "18495551234",                      // Teléfono con código país o group ID
  "type": "text|image|audio|video|document|location|contacts|template|interactive|reaction|sticker",
  
  // Uno de estos, según type:
  "text": { "body": "Hola, su cotización..." },
  "image": { "id": "{Media-ID}", "caption": "..." },
  "document": { "id": "{Media-ID}", "filename": "cotizacion.pdf", "caption": "..." },
  "video": { "id": "{Media-ID}", "caption": "..." },
  "audio": { "id": "{Media-ID}" },
  "location": { "latitude": 18.4861, "longitude": -69.9312, "name": "ALIUN Travel", "address": "..." },
  "contacts": [{ "name": {...}, "phones": [...] }],
  "template": { "name": "...", "language": {...}, "components": [...] },
  "interactive": { "type": "button|list|flow", ... },
  "reaction": { "message_id": "...", "emoji": "👍" },
  "sticker": { "id": "{Media-ID}" },
  
  "context": { "message_id": "wamid.XXXX" }  // Para responder a un mensaje
}
```

### 3.2 MessageResponsePayload — Respuesta de Envío

```json
{
  "messaging_product": "whatsapp",
  "contacts": [{ "input": "18495551234", "wa_id": "18495551234" }],
  "messages": [{ "id": "wamid.HBgLMTg0OTU1NTEyMzQ..." }]
}
```

### 3.3 InteractiveMessage — Mensajes Interactivos ⭐

```json
{
  "type": "button|list|flow|catalog_message|product|product_list|call_permission_request",
  "header": { "type": "text|image|video|document", "text": "..." },
  "body": { "text": "Seleccione una opción" },
  "footer": { "text": "ALIUN Travel SRL" },
  "action": {
    // Para button:
    "buttons": [
      { "type": "reply", "reply": { "id": "btn_cotizar", "title": "📋 Cotizar" } },
      { "type": "reply", "reply": { "id": "btn_info", "title": "ℹ️ Más Info" } }
    ],
    // Para list:
    "button": "Ver opciones",
    "sections": [{ "title": "Hoteles", "rows": [...] }],
    // Para flow:
    "name": "flow",
    "flow_id": "{Flow-ID}",
    "flow_token": "cotizacion_flow_token",
    "flow_action": "navigate",
    "flow_action_payload": { "screen": "HOTEL_SEARCH", "data": {} }
  }
}
```

### 3.4 TemplateMessage — Mensajes Template

```json
{
  "name": "cotizacion_disponible",
  "language": { "code": "es", "policy": "deterministic" },
  "components": [
    {
      "type": "header",
      "parameters": [{ "type": "image", "image": { "id": "{Media-ID}" } }]
    },
    {
      "type": "body",
      "parameters": [
        { "type": "text", "text": "Juan Pérez" },
        { "type": "text", "text": "Barceló Bávaro Palace" }
      ]
    },
    {
      "type": "button",
      "sub_type": "url",
      "index": "0",
      "parameters": [{ "type": "text", "text": "https://aliuntravelsrl.com/cotiz/abc123" }]
    }
  ]
}
```

### 3.5 MarketingMessageRequestPayload — Marketing Masivo

```json
{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "18495551234",
  "type": "template",
  "template": { "name": "hot_sale_promo", "language": {...}, "components": [...] },
  "product_policy": "CLOUD_API_FALLBACK|STRICT",
  "message_activity_sharing": true
}
```

### 3.6 WebhookPayload — Eventos Recibidos

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "{WABA-ID}",
      "changes": [
        {
          "field": "messages|group_lifecycle_update|group_settings_update|group_participant_update",
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "+18495551234",
              "phone_number_id": "{Phone-Number-ID}"
            },
            "contacts": [
              {
                "profile": { "name": "Juan Pérez" },
                "wa_id": "18495551234"
              }
            ],
            "messages": [
              {
                "from": "18495551234",
                "id": "wamid.HBgL...",
                "timestamp": "1716211200",
                "type": "text",
                "text": { "body": "Quiero cotizar Barceló Bávaro" }
              }
            ],
            "statuses": [
              {
                "id": "wamid.HBgL...",
                "status": "sent|delivered|read|failed",
                "timestamp": "1716211200",
                "recipient_id": "18495551234",
                "conversation": {
                  "id": "...",
                  "expiration_timestamp": "...",
                  "origin": { "type": "..." }
                },
                "pricing": {
                  "billable": true,
                  "pricing_model": "CBP|PMP",
                  "category": "..."
                }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### 3.7 ConversationalAutomation — Bienvenida y Comandos

```json
// POST /{Phone-Number-ID}/conversational_automation
{
  "enable_welcome_message": true,
  "prompts": [
    "📋 Cotizar un hotel",
    "🏖️ Ver ofertas disponibles",
    "📞 Hablar con un asesor"
  ],
  "commands": [
    { "name": "cotizar", "description": "Iniciar proceso de cotización" },
    { "name": "ofertas", "description": "Ver ofertas del día" },
    { "name": "ayuda", "description": "Hablar con asesor humano" }
  ]
}
```

---

## 4. Tipos de Mensaje Soportados

| Tipo | Propósito | Ejemplo ALIUN |
|---|---|---|
| `text` | Mensaje de texto simple | "Su cotización está lista" |
| `image` | Imagen con caption | Foto del hotel + "Habitación Deluxe" |
| `video` | Video con caption | Tour virtual del hotel |
| `audio` | Audio | Nota de voz del asesor |
| `document` | Archivo con nombre | PDF de cotización |
| `location` | Ubicación GPS | Ubicación del hotel |
| `contacts` | Tarjeta de contacto | Datos del asesor |
| `template` | Template pre-aprobado | Cotización lista con botón URL |
| `interactive` | Botones / listas / flows | "Seleccione hotel" → botones |
| `reaction` | Emoji en mensaje existente | 👍 confirmación |
| `sticker` | Sticker | Greeting stickers |

---

## 5. Flows ⭐ — Formularios Dentro de WhatsApp

Los Flows son la funcionalidad más poderosa para ALIUN. Permiten crear **mini-apps dentro de WhatsApp** sin que el usuario salga del chat.

### Arquitectura de Flow

```
Cliente WhatsApp → Flow (formulario nativo) → Data Screen → Endpoint → atlas-sales-mcp
```

### Endpoints de Flow

| Operación | Endpoint | Body |
|---|---|---|
| Crear | `POST /{WABA-ID}/flows` | multipart/form-data |
| Obtener | `GET /{Flow-ID}` | — |
| Actualizar JSON | `POST /{Flow-ID}/assets` | multipart/form-data |
| Publicar | `POST /{Flow-ID}/publish` | — |
| Deprecar | `POST /{Flow-ID}/deprecate` | — |
| Eliminar | `DELETE /{Flow-ID}` | — |

### Flow para Cotización ALIUN (ejemplo conceptual)

```json
{
  "screen": "HOTEL_SEARCH",
  "data": {
    "hotels": ["Barceló Bávaro Palace", "Riu Bambu", "Dreams Onyx"],
    "check_in": "",
    "check_out": "",
    "adults": 2,
    "children": 0
  }
}
```

El usuario selecciona hotel → ingresa fechas → el Flow envía data al endpoint → `atlas-sales-mcp` calcula cotización → retorna `landing_url`.

---

## 6. Modelo de Precios (Conversations-Based Pricing)

| Categoría | Costo | Ejemplo |
|---|---|---|
| **Authentication** | Más bajo | Código OTP login |
| **Marketing** | Medio | Promociones, ofertas |
| **Utility** | Bajo | Confirmaciones, receipts |
| **Service** | Más alto | Atención al cliente (initiado por usuario) |

- **CBP** = Conversation-Based Pricing (pago por conversación)
- **PMP** = Partner-Markup Pricing
- Ventana de conversación: 24 horas desde el último mensaje del usuario
- Mensajes fuera de ventana = requieren template (pago adicional)

---

## 7. Webhook Events (Campos de Suscripción)

| Campo | Eventos |
|---|---|
| `messages` | Mensajes entrantes, status de entrega (sent/delivered/read/failed) |
| `group_lifecycle_update` | Creación/eliminación de grupo |
| `group_settings_update` | Cambios en settings del grupo |
| `group_participant_update` | Entrada/salida de participantes |

### Flujo de Verificación Webhook

1. Meta envía `GET /webhook?hub.verify_token={TOKEN}&hub.challenge={CHALLENGE}`
2. Tu servidor responde con `{CHALLENGE}` (200 OK)
3. Meta confirma la suscripción
4. Meta envía eventos vía `POST /webhook`

---

## 8. Códigos de Error Comunes

| HTTP | Código | Significado |
|---|---|---|
| 400 | — | Request malformado, parámetros inválidos |
| 401 | 190 | Token expirado o inválido |
| 403 | — | Sin permisos para el recurso |
| 404 | — | Recurso no encontrado |
| 422 | — | Entidad no procesable |
| 429 | — | Rate limit excedido |
| 500 | — | Error interno de Meta |

---

## 9. Diagrama de Integración ALIUN

```
                        ┌─────────────────────────────┐
                        │     Meta Business Suite      │
                        │  (Templates, Flows, Ads)     │
                        └──────────┬──────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
              Webhook        Marketing      Conversational
              Events        Messages       Automation
                    │              │              │
                    └──────────────┼──────────────┘
                                   │
                            ┌──────▼──────┐
                            │  n8n        │
                            │  (router)   │
                            └──────┬──────┘
                                   │
                    ┌──────────────┼──────────────┐
                    ▼              ▼              ▼
            atlas-sales-mcp   crm_leads      Chatwoot
            (13 tools + 5)   (pipeline)     (inbox)
                    │              │              │
                    ▼              ▼              ▼
              Supabase        Horizons       WhatsApp
              (SSOT)         (admin)         (canal)
```

### Flujo Completo de Cotización vía WhatsApp API

```
1. Meta Ad → aliuntravelsrl.com → usuario escribe por WhatsApp
2. Webhook POST → n8n → clasifica mensaje
3. n8n → atlas-sales-mcp: buscar_hoteles("barcelo")
4. MCP → Supabase → retorna lista de hoteles
5. n8n → WhatsApp API: interactive message (botones con hoteles)
6. Usuario selecciona hotel → Webhook → n8n
7. n8n → atlas-sales-mcp: calcular_cotizacion(hotel, fechas, adultos)
8. MCP → Supabase RPC → retorna precios
9. n8n → WhatsApp API: template message con landing_url
10. Usuario abre landing → ve cotización branded → descarga PDF
11. n8n → atlas-sales-mcp: crear_deal(lead_id, cotizacion_id)
12. Lead avanza en pipeline CRM
```

---

## 10. Checklist de Implementación ALIUN

### Fase 0 — Cuenta Business API
- [ ] Verificar WhatsApp Business Account activa en Meta Business Suite
- [ ] Obtener WABA-ID y Phone-Number-ID
- [ ] Generar Access Token (permanente o refresh)
- [ ] Configurar webhook verification token
- [ ] Aprobar templates iniciales (cotización, bienvenida, follow-up)

### Fase 1 — Webhook Receiver
- [ ] Endpoint `POST /webhook` en n8n o servidor propio
- [ ] Verificación `GET /webhook?hub.verify_token=...`
- [ ] Suscribir app a WABA webhooks
- [ ] Probar recepción de mensajes

### Fase 2 — Mensajería Básica
- [ ] POST /messages (texto) → confirmar funciona
- [ ] POST /messages (interactive buttons) → menú principal
- [ ] POST /messages (document) → enviar PDF cotización
- [ ] POST /messages (template) → cotización con botón URL

### Fase 3 — Conversational Automation
- [ ] Configurar welcome message + ice breakers
- [ ] Configurar bot commands (/cotizar, /ofertas, /ayuda)

### Fase 4 — Flows
- [ ] Crear Flow de cotización (selección hotel → fechas → adultos)
- [ ] Publicar Flow
- [ ] Integrar con atlas-sales-mcp

### Fase 5 — Marketing
- [ ] Crear templates de marketing (Hot Sale, Black Friday)
- [ ] Configurar schedules para envíos masivos
- [ ] Medir conversión por template

---

## 11. Schemas Completos por Categoría

### Mensajes (12 schemas)
- `MessageRequest`, `MessageResponsePayload`, `Message`, `MessageStatus`, `MessageContext`, `MessageResponse`, `TextMessage`, `ImageMessage`, `DocumentMessage`, `VideoMessage`, `AudioMessage`, `BaseMessageProperties`

### Interactivos (5 schemas)
- `InteractiveMessage`, `InteractiveObject`, `InteractiveMessageReply`, `InteractiveListReplyContent`, `InteractiveButtonReplyContent`

### Templates (3 schemas)
- `TemplateMessage`, `TemplateObject`, `TemplateComponent`

### Marketing (2 schemas)
- `MarketingMessageRequestPayload`, `MarketingMessageResponsePayload`

### Webhook (3 schemas)
- `WebhookPayload`, `WebhookConfiguration`, `WebhookUpdateState`

### Contactos (5 schemas)
- `ContactObject`, `ContactResponse`, `ContactProfile`, `ContactSharingMessage`, `NameObject`

### Botones (5 schemas)
- `ButtonComponent`, `ButtonParameterObject`, `ButtonPayloadParameter`, `ButtonTextParameter`, `ButtonMessage`

### Media (3 schemas)
- `MediaObject`, `MediaMessage`, `MediaMessageProperties`

### Grupos (4 schemas)
- `GroupInfo`, `GroupValue`, `GroupParticipant`, `GroupProfilePicture`

### Pricing/Conversación (2 schemas)
- `Conversation`, `Pricing`

### Status (2 schemas)
- `Statuses`, `StatusMessageValue`

### Errores (8 schemas)
- `GraphAPIError`, `ErrorObject`, `ErrorResponse`, `ErrorData`

### Comercio (2 schemas)
- `CurrencyParameter`, `CurrencyObject`

### Llamadas (7 schemas)
- `CallPermissionCheckResponsePayload`, `CallRequestPayload`, `CallResponsePayload`, etc.

### Paginación (9 schemas)
- `CursorPaging`, `PaginationCursors`, `PagingInfo`, etc.

---

## 12. Comparativa: WhatsApp Business API vs OpenWA

| Aspecto | WhatsApp Business API (oficial) | OpenWA (whatsapp-web.js) |
|---|---|---|
| **Status** | Oficial Meta | No oficial (reverse-engineering) |
| **Riesgo ban** | Cero | Alto |
| **RAM** | 0 (REST API) | 300-500MB/sesión (Puppeteer) |
| **Costo** | $0.005/conversación servicio | Gratis |
| **Templates** | ✅ Gestión completa | ❌ No soportado |
| **Flows** | ✅ Formularios nativos | ❌ No existe |
| **Marketing masivo** | ✅ Endpoint dedicado | ❌ Riesgo de ban |
| **QR codes** | ✅ API nativa | ❌ No |
| **Groups** | ✅ API completa | ✅ Vía Puppeteer |
| **Status delivery** | ✅ Webhook oficial | ✅ Vía Puppeteer |
| **Leer mensajes** | ✅ Webhook | ✅ Más rápido (local) |
| **Multi-sesión** | 1 número por token | Múltiples en 1 instancia |
| **Confiabilidad** | Estable, SLA Meta | Se rompe con updates WA |
| **Onboarding** | Requiere verificación Meta | Docker + QR scan |

### Recomendación ALIUN: **Stack Híbrido**

```
WhatsApp Business API (oficial)  →  Cotización, templates, marketing, flows
         +
OpenWA (whatsapp-web.js)        →  Lectura de mensajes instantánea, grupos, sesiones humanas
```

---

## 13. Recursos

- **Repo OpenAPI:** https://github.com/facebook/openapi
- **Spec YAML:** business-messaging-api_v23.0.yaml (1MB)
- **Docs oficiales:** https://developers.facebook.com/documentation/business-messaging/whatsapp/overview
- **Business SDK:** https://developers.facebook.com/docs/business-sdk/getting-started
- **Graph API Explorer:** https://developers.facebook.com/tools/explorer/
- **Meta Business Suite:** https://business.facebook.com/

---

*Documento generado por Hermes Agent · ATLAS-HERMES · 20 MAY 2026*
*Basado en spec oficial Meta OpenAPI v23.0 · 113 endpoints · 369 schemas*
