# Estado actual — FCV Citas

**Actualizado:** 2026-10-04 (cierre del día). Resumen operativo; la fuente de verdad sigue siendo `AGENTS.md` y la LLM Wiki (`citas-api/docs/FCV Dev/llm-wiki/wiki/index.md`).

## Producto

- RF-01 a RF-20 implementados y probados.
- **35 de 36 HU `Completada`.** Solo falta HU-036 (WF-003, bonus): necesita una ejecución con citas `APPROVED` del mismo día.
- HU-033 se cerró con una deuda visual aceptada por el usuario: sin aprobación de Stitch/AI Studio.

| Repo | Rama | Último commit | Pruebas |
|---|---|---|---|
| `citas-api` | `develop` | `1e5b2d8` docs(hu-033) | Maven 72/72, estable con datos ajenos (LOOP_03) |
| `citas-web` | `develop` | `940e1a3` feat(hu-011) | lint, Vitest 44/44 y build (2026-10-04) |
| `citas` (raíz) | `develop` | ver `git log` | — |

`main` sigue en S2 en los tres repos. **Decisión del usuario:** hacer el merge `develop → main` al final, después de HU-036, sin squash ni rebase y avisando antes del push.

## Entregables por sesión

| Sesión | Estado | Evidencia |
|---|---|---|
| S5 | Cerrada | WF-001 JSON + validación; MCP conectado e invocado; contenido no confiable y riesgos residuales: `citas-api/docs/FCV Dev/evidence/S5-*.md` |
| S6 | Casi cerrada | WF-002 publicado y validado de extremo a extremo (`S6-WF-002-notificaciones.md`); WF-003 validado salvo CA-01 |
| S4 | LOOP_03 entregado | `citas-api/docs/FCV Dev/evidence/LOOP_03-pruebas-fragiles.md` |

## Cómo levantar el entorno

1. `docker compose up -d`.
2. API: `docker compose exec -d -e SPRING_PROFILES_ACTIVE=local citas-api-dev sh -c 'mvn -q spring-boot:run > /tmp/api.log 2>&1'`, que deja `http://localhost:8080` disponible con health, `/v3/api-docs` y Swagger.
3. Web: `docker compose exec -d citas-web-dev sh -c 'npm run dev -- --host 0.0.0.0 --port 5173 > /tmp/web.log 2>&1'`.
4. Para que n8n alcance la API (WF-001/WF-003), el usuario abre el túnel en su terminal:
   `& "$env:LOCALAPPDATA\fcv-tools\cloudflared.exe" tunnel --no-autoupdate --url http://localhost:8080`.
   La URL cambia en cada arranque y se configura solo en los nodos `Config` dentro de n8n.

## n8n (instancia compartida, prefijo `Andrey`)

- **WF-002:** publicado. La API lo invoca con `N8N_STATUS_WEBHOOK_URL`, definido en el `.env` raíz, que no se versiona.
- **WF-001:** recordatorios con ventana de 24 h. Validado y sin publicar.
- **WF-003:** resumen diario a las 06:00. Validado y sin publicar.
- **MCP:** `andrey-n8n` registrado en Claude Code (ámbito local, OAuth).

## Pendientes

1. **HU-036:** abrir el túnel, actualizar la URL en WF-003 y ejecutarlo un día con citas `APPROVED` del mismo día. La cita sintética #10 es del 2026-10-05.
2. **Merge `develop → main`** en los tres repos, con confirmación del usuario.
3. **Sustentación técnica:** material opcional.
4. **Decidido el 2026-10-04:**
   - el repo raíz `citas` sigue público (excepción de orquestación);
   - el calendario USER ("opción A") queda fuera como mejora futura.
5. **Mejoras futuras y menores:**
   - edición de especialidades en la UI;
   - agregado diario por estado (B4);
   - el hash del seed no coincide con `Demo1234*`;
   - el usuario debe revocar el PAT de GitHub del 2026-09-29.
