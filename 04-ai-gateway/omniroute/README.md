# 🚀 OmniRoute AI Gateway — Aliun Travel

Módulo oficial de integración de **OmniRoute** como Gateway de Inferencia y Resiliencia para **Hermes Swarm** (Ventas, Marketing, QA) y **n8n**.

## 📁 Contenido del Módulo

*   **[GTI-OMNIROUTE-AI-GATEWAY.md](GTI-OMNIROUTE-AI-GATEWAY.md):** Guía Técnica de Integración completa con arquitectura, combos y manual de uso.
*   **[docker-compose.omniroute.yml](docker-compose.omniroute.yml):** Manifiesto Docker listo para producción en VPS3 o local.
*   **[config.example.json](config.example.json):** Plantilla de combos (`combo-ventas-realtime`, `combo-marketing-batch`) y reglas de circuit breaker.

## ⚡ Inicio Rápido

```bash
# 1. Copiar configuración de ejemplo
cp config.example.json config.json

# 2. Iniciar gateway con Docker
docker compose -f docker-compose.omniroute.yml up -d

# 3. Probar conexión
curl http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer aliun-secret-gateway-2026" \
  -d '{"model":"auto","messages":[{"role":"user","content":"Ping"}]}'
```
