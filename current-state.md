# Estado actual — FCV Citas

**Actualizado:** 2026-10-04. Resumen operativo; la fuente de verdad sigue siendo `AGENTS.md` y la LLM Wiki (`citas-api/docs/FCV Dev/llm-wiki/wiki/index.md`).

## Producto

- RF-01 a RF-20 implementados y probados. RF-20 (OpenAPI) quedó cerrado el 2026-10-04.
- 32 de 36 HU `Completada`.
- Pendientes:
  - HU-033 (integración web, en progreso);
  - HU-034, 035 y 036 (n8n, `Pendiente de aprobación`).

| Repo | Rama | Último commit | Pruebas |
|---|---|---|---|
| `citas-api` | `develop` | `bd22790` feat(s5): OpenAPI, health, webhook n8n real | Maven 72/72 (hook de commit) |
| `citas-web` | `develop` | `940e1a3` feat(hu-011): "Mi afiliación" | Vitest 44/44, lint y build (2026-09-30) |
| `citas` (raíz) | `develop` | ver `git log` | — |

`main` sigue en S2 en los tres repos; el merge `develop → main` espera la decisión del usuario.

## Cómo levantar el entorno

1. `docker compose up -d`. Los contenedores de la API y la web quedan en espera.
2. API: `docker compose exec -d -e SPRING_PROFILES_ACTIVE=local citas-api-dev sh -c 'mvn -q spring-boot:run > /tmp/api.log 2>&1'`. Queda en `http://localhost:8080`:
   - `GET /actuator/health`;
   - `GET /v3/api-docs`;
   - Swagger UI en `/swagger-ui/index.html`.
3. Web: `docker compose exec -d citas-web-dev sh -c 'npm run dev -- --host 0.0.0.0 --port 5173 > /tmp/web.log 2>&1'`. Queda en `http://localhost:5173`; tras editar `citas-web` hay que reiniciarlo.
4. Pruebas backend: `docker compose exec citas-api-dev mvn test`. La BD de pruebas de compose es persistente.

## Integraciones n8n (S5/S6)

- **API:**
  - El webhook real WF-002 está listo y se activa con `N8N_STATUS_WEBHOOK_URL` y `N8N_STATUS_WEBHOOK_BEARER_TOKEN` en el `.env` raíz; después hay que recrear `citas-api-dev`.
  - Eventos: `appointment.status.changed` y `appointment.reschedule.decided`.
  - Contrato en la wiki `contracts.md`.
- **Instancia n8n:**
  - La del trainer es **compartida**: todos nuestros recursos llevan el prefijo `Andrey` y no se tocan los ajenos.
  - Aún no hay workflows ni credenciales propios.
- **Plan corregido:** `PLAN_IMPLEMENTACION_FLUJOS_N8N.md`.
- **Bloqueos actuales:**
  1. n8n no alcanza `localhost:8080`: falta un túnel temporal, que el usuario debe abrir o autorizar.
  2. El acceso MCP propio está pendiente de generar en n8n, con la sesión abierta por el usuario.

## Pendientes

1. **S5:**
   - WF-001 y su JSON;
   - evidencia de invocación MCP;
   - documento de riesgos residuales con la demo del issue envenenado.
2. **S6:**
   - WF-002 workflow y su JSON;
   - WF-003 (bonus);
   - HU-033 a 036.
3. **Entrega:**
   - evidencia de `LOOP_03`, propio del estudiante;
   - merge `develop → main`, previa confirmación.
4. **Decisiones abiertas:**
   - repo raíz publicado frente a la regla de "dos repos públicos";
   - pantallas sin aprobación Stitch;
   - calendario USER (`PLAN_TRABAJO_CALENDARIO_USER.md`), no implementado aquí.
5. **Seguridad (lo hace el usuario):** revocar el PAT de GitHub expuesto el 2026-09-29.
