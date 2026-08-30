# 🔧 GTI-OMNIROUTE-001: AI GATEWAY & LLM RESILIENCE SYSTEM
## Guía Técnica de Integración (GTI) — OmniRoute Gateway para Hermes Swarm & n8n
**Organización:** ALIUN TRAVEL SRL  
**Repositorio:** `atlas-api-toolbox`  
**Ubicación:** `04-ai-gateway/omniroute/GTI-OMNIROUTE-AI-GATEWAY.md`  
**Clasificación:** Herramienta de Infraestructura de Ejecución (Nivel 5 — Arquitectura de la Verdad)  
**Fecha:** 30 de Agosto, 2026  
**Estado:** OFICIAL / IMPLEMENTABLE  

---

### 1. Resumen Ejecutivo y Propósito
**OmniRoute** es el **AI Gateway y Proxy de Resiliencia** oficial adoptado para blindar las operaciones de inteligencia artificial en **ALIUN TRAVEL SRL**. Actúa como una capa intermedia entre los consumidores internos (Hermes Swarm, n8n, Antigravity, portales web) y más de 350 proveedores de LLMs.

#### Objetivos Primarios para Aliun Travel:
1. **Eliminar Caídas en Ventas (Zero-Downtime WhatsApp/Chatwoot):** Prevenir que caídas de API o límites de cuota (HTTP 429 Rate Limit) dejen a un cliente desatendido en WhatsApp o Web. Si el proveedor principal falla, conmuta automáticamente en milisegundos a un backend secundario.
2. **Abaratar Costos de Marketing y Tareas Rutinarias:** Implementar compresión de tokens (RTK + Caveman) y enrutamiento económico (`auto/cheap`) para tareas de volumen (Sentinel QA, resúmenes, extracción de datos), reservando modelos frontier costosos exclusivamente para copy estratégico y razonamiento complejo.
3. **Punto Único de Configuración:** Centralizar todas las credenciales y auditoría en un solo endpoint compatible con el estándar de OpenAI (`http://localhost:20128/v1` o `http://vps3.aliuntravelsrl.com:20128/v1`).

---

### 2. Arquitectura de Integración en el Ecosistema ALIUN

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        CONSUMIDORES DE INFERENCIA                      │
│                                                                        │
│   [Hermes Commercial]      [Hermes Marketing]        [n8n Workflows]   │
│   (WhatsApp/Chatwoot)     (Sentinel/Copies/SEO)     (Pipelines Auto)   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼ (HTTP / OpenAI Wire Format)
┌────────────────────────────────────────────────────────────────────────┐
│             OMNIROUTE AI GATEWAY (Puerto 20128 / Endpoint /v1)          │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ 1. Capa de Compresión RTK + Caveman (Ahorro 15%–95% tokens)      │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ 2. Router Inteligente (19 Estrategias: Auto, Cheap, LKGP)        │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │ 3. Resiliencia en 3 Capas:                                       │  │
│  │    • Provider Circuit Breaker (5xx / Timeout → Siguiente)        │  │
│  │    • Key Cooldown (429 Rate Limit → Siguiente Key)               │  │
│  │    • Model Lockout (Fallback per-model)                          │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
  [Tier 1: Frontier]         [Tier 2: Fast & Cheap]       [Tier 3: Free / Local]
  • Claude 3.5 Sonnet        • DeepSeek-V3 / Kimi K3      • Gemini 1.5 Flash (Free)
  • GPT-4o                   • Claude 3.5 Haiku           • Mistral / Ollama Local
```

---

### 3. Perfiles de Enrutamiento (Combos) para ALIUN

OmniRoute permite definir "Combos" (cadenas de prioridad con fallback automático). Para Aliun Travel se establecen dos perfiles oficiales:

#### Perfil A: `combo-ventas-realtime` (Alta Disponibilidad, Baja Latencia)
*   **Destinado a:** `Hermes Commercial`, WhatsApp Business API, Chatwoot Web Widget.
*   **Estrategia:** `lkgp` (Last-Known-Good Path) + `priority`.
*   **Cadena de Fallback:**
    1.  *Primario:* Claude 3.5 Haiku / GPT-4o-mini (Respuesta humana inmediata).
    2.  *Fallback 1:* Gemini 1.5 Flash (Ultra-rápido, costo mínimo).
    3.  *Fallback 2 (Emergencia):* DeepSeek-Chat / Kimi K3.
*   **Comportamiento ante error:** Si el Primario arroja 429 o timeout en >3 segundos, conmuta de inmediato a Fallback 1 sin que el cliente note la interrupción.

#### Perfil B: `combo-marketing-batch` (Alto Volumen, Máxima Economía)
*   **Destinado a:** `Hermes Marketing`, `Sentinel` (Quality Score), extracción de datos competitivos de Atlas-Intel, workflows n8n.
*   **Estrategia:** `cost-optimized` + compresión de contexto RTK habilitada.
*   **Cadena de Fallback:**
    1.  *Primario:* DeepSeek-V3 / Kimi K3 / Gemini Flash (Costo fraccional).
    2.  *Fallback:* Mistral / Groq / OpenRouter.
    3.  *Supervisor de Calidad:* Claude 3.5 Sonnet (Solo invocado si Sentinel califica el copy por debajo de 85 puntos).

---

### 4. Resiliencia Activa: Disyuntores y Cooldowns

OmniRoute previene que los errores se propaguen hacia los agentes mediante 3 capas independientes:

| Capa de Fallo | Disparador | Acción de OmniRoute | Impacto en el Swarm |
| :--- | :--- | :--- | :--- |
| **Capa 1: Proveedor caído** | Errores 500, 502, 503, 504 o Timeout. | Abre el disyuntor por 30s. Rerutea el tráfico al siguiente proveedor de la cadena. | Cero llamadas perdidas. |
| **Capa 2: Clave agotada (Rate Limit)** | Error HTTP 429. | Pone la clave en Cooldown respetando la cabecera `Retry-After`. Pasa a la siguiente clave del pool. | El agente continúa trabajando. |
| **Capa 3: Modelo no disponible** | 404 o incompatibilidad modal. | Bloquea únicamente ese modelo dentro de la conexión, manteniendo el resto activo. | No se tumba el proveedor completo. |

---

### 5. Guía de Despliegue Operativo

#### Opción A: Despliegue con Docker Compose (Recomendado en VPS3 / Servidor)
Crear el archivo `docker-compose.omniroute.yml` (incluido en este directorio) y ejecutar:
```bash
docker compose -f docker-compose.omniroute.yml up -d
```
Verificar que el servicio responda:
```bash
curl http://localhost:20128/v1/models
```

#### Opción B: Ejecución Local / Node.js
```bash
npm install -g omniroute
omniroute
```

---

### 6. Configuración de Consumidores Internos

#### En n8n:
1. Crear una credencial de tipo **OpenAI API**.
2. **Base URL:** `http://localhost:20128/v1` (o la IP interna del VPS).
3. **API Key:** La clave configurada en OmniRoute (o `omniroute-local-secret`).
4. **Model:** `auto` o `combo-ventas-realtime`.

#### En Scripts de Python / Node.js (Hermes Swarm):
```javascript
import OpenAI from 'openai';

const ai = new OpenAI({
  baseURL: 'http://localhost:20128/v1',
  apiKey: process.env.OMNIROUTE_API_KEY || 'sk-omniroute-internal'
});

// Llamada con auto-fallback garantizado
const response = await ai.chat.completions.create({
  model: 'auto/coding', // o 'combo-ventas-realtime'
  messages: [{ role: 'user', content: 'Analizar lead entrante' }]
});
```

---

### 7. Gobernanza y Cumplimiento Constitucional (COS)
1. **Clasificación Estricta:** OmniRoute es una herramienta de infraestructura (Nivel 5 de la Arquitectura de la Verdad). No posee soberanía institucional ni facultades de decisión.
2. **Separación de Poderes:** Las decisiones sobre precios, inventarios y presupuestos siguen rigiéndose por la firma humana del Director y registrándose en `marketing_decision_evidence` (DEP).
3. **Sustituibilidad:** Si en el futuro surge una solución superior, OmniRoute puede ser reemplazado sin alterar los prompts, contratos ni lógica de los agentes del Swarm.
