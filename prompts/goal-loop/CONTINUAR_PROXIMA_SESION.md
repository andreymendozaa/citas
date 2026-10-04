# Prompt de continuación — retomar el proyecto FCV Citas

> Pega este archivo completo (o su contenido) como primer mensaje de la próxima sesión con Claude Code para retomar exactamente donde quedó el trabajo.

## Contexto para el agente

Lee primero, en este orden:
1. `CLAUDE.md` (raíz)
2. `AGENTS.md` (raíz)
3. `citas-api/AGENTS.md`
4. `citas-web/AGENTS.md`
5. `citas-api/docs/FCV Dev/llm-wiki/wiki/index.md`
6. `citas-api/docs/FCV Dev/llm-wiki/wiki/traceability.md` (auditoría y cierre del 2026-09-30)

Esos archivos son la fuente de verdad. Este prompt es solo un resumen operativo de continuidad y no los reemplaza.

**Idioma:** toda la retroalimentación y las preguntas al usuario van en español. Los mensajes de commit siguen en inglés, como el historial existente.

## Actualización 2026-10-04

- Estado vivo en `current-state.md` (raíz). Plan n8n corregido en `PLAN_IMPLEMENTACION_FLUJOS_N8N.md`.
- `citas-api` `bd22790`:
  - OpenAPI (HU-004 `Completada`) y `/actuator/health`;
  - webhook real WF-002 con el evento `appointment.reschedule.decided`;
  - Maven 72/72.
- Decisiones del usuario sobre n8n:
  - cuenta compartida: prefijo `Andrey` y no tocar lo ajeno;
  - MCP propio;
  - Gmail con su cuenta Google;
  - túnel autorizado por el usuario, aunque los permisos del agente lo bloquearon y debe abrirse o permitirse explícitamente.

## Estado al cierre de la sesión del 2026-09-30

### Resumen
- **S4 cerrado y todos los requerimientos funcionales del PRD (RF-01 a RF-19) implementados y probados.**
- 31 de 36 HU en `Completada`.
- Pruebas: Maven 66/66 y Vitest 44/44 con lint y build en verde.
- Todo está empujado a `origin/develop` en los tres repos.

| Repo | Último commit |
|---|---|
| `citas` | el commit que guarda este archivo (`docs: full continuation prompt…`; ver `git log`) |
| `citas-api` | `76b4f84` feat(hu-011): consult and change the user's insurance affiliation; seed regimes (V5) |
| `citas-web` | `940e1a3` feat(hu-011): "Mi afiliación" section in the user profile |

### Lo realizado el 2026-09-30 (en orden)
1. **Frontend consolidado de S4** (HU-008/009/010/012/013/029/030/031/032):
   - recuperación y restablecimiento de contraseña;
   - perfil;
   - EPS y planes;
   - agenda profesional con cierre de atención;
   - bandeja ADMIN unificada;
   - historial de estados;
   - pestañas por rol en el dashboard.
2. **Revisión integral de requerimientos y auditoría Scrum** de HU-003, 004 y 014 a 028.
   - Criterio: un CA es PASS solo con prueba automatizada o propiedad estructural.
   - El informe completo está en la wiki (`traceability.md`).
3. **Pruebas dedicadas y corrección de bugs, siguiendo Red → Green:**

   | Clase de prueba | HU | Bug corregido |
   |---|---|---|
   | `AppointmentLifecycleIntegrationTest` | HU-026 a 028 | 3 errores 500 |
   | `SpecializedDecisionIntegrationTest` | HU-023/024 | 1 error 500 |
   | `OfferAndAgendaRulesIntegrationTest` | HU-014 a 020 | Bloques pasados editables y eliminables |
   | `FixedCatalogsIntegrationTest` | HU-003 | — |

   Todos los errores 500 venían de `EmptyResultDataAccessException` sin manejar. Ya no queda ningún `queryForMap` en el backend.
4. **Funcionales pequeñas:**
   - `GET /catalogs/reschedule-statuses` (HU-003);
   - `primarySpecialtyId` en `GET /admin/professionals`, más selector de primaria y editor de asignaciones en la UI (HU-016);
   - filtro "Tipo de cita" en la reserva (HU-021).
5. **HU-011 (afiliación).** El usuario aprobó ampliar el alcance a consultar y cambiar la afiliación, y sembrar los 5 regímenes de referencia.
   - `GET/PUT /users/me/affiliation`, sin duplicar planes.
   - Migración `V5__insurance_regimes_seed.sql`.
   - Sección *Mi afiliación* en *Mi perfil*.
   - Solo son seleccionables los planes activos de una EPS activa, también en `/catalogs/plans`.

## Qué falta (en orden recomendado)

1. **S5:**
   - Swagger/OpenAPI con `springdoc-openapi-starter-webmvc-ui` 2.8.13; cierra HU-004 y RF-20.
   - Crear `current-state.md` en la raíz.
   - WF-001 (recordatorios) exportado en JSON en `citas-api/automations/n8n/`; hoy solo existen especificaciones `.md`.
   - Evidencia de MCP con n8n.
   - Documento de riesgos residuales (contenido no confiable).
2. **S6:**
   - WF-002: webhook real hacia n8n, conectado al puerto ya preparado `Ports.AppointmentEvents`, sin tocar `SchedulingJdbcAdapter`.
   - WF-003 (opcional).
   - HU-033 (integración web, en progreso) y HU-034 a 036 (`Pendiente de aprobación`).
3. **Entregables de evaluación:**
   - Merge `develop → main` cuando el usuario lo decida; `main` sigue en S2 en los tres repos. **Confirmar antes.**
   - Evidencia del LOOP propio del estudiante (`LOOP_03`) y sus logs.
4. **Pendiente de decisión del usuario:**
   - El repositorio raíz `citas` está publicado, en conflicto con "solo dos repos públicos" (`RESTRICCIONES_TECNICAS.md`) y con "No inicializar Git en la raíz" (`AGENTS.md`).
   - Aprobación visual Stitch/AI Studio: no existe para ninguna pantalla; las de S4 se construyeron extendiendo el estilo existente.
5. **Mejoras menores (fuera de los CA):**
   - editar nombre y duración de especialidades en la UI;
   - Actuator health;
   - corregir `database/seed-lab-scheduling.sql` o `README_DB.md`, porque el hash no corresponde a `Demo1234*`.
6. **Seguridad, lo hace el usuario:** revocar el PAT de GitHub expuesto el 2026-09-29.

## Entorno y datos de prueba (BD de desarrollo)

**Cuentas sintéticas** (contraseña reasignada localmente porque el hash del seed no coincide con la documentada):

| Cuenta | Rol | Contraseña |
|---|---|---|
| `lab.admin@citas.test` | ADMIN | `LabDemo123*` |
| `lab.cardio@citas.test` | PROFESSIONAL | `LabDemo123*` |
| `lab.paciente@citas.test` | USER | `LabDemo123*` |
| `lab.usuario@citas.test` | USER | `LabReset456*` (cambiada con el flujo de restablecimiento) |

**Datos creados durante las validaciones:**
- EPS `LAB-EPS-01` con el plan `LAB-CONTRIB-01`;
- cita pasada "LAB: cita pasada por cerrar";
- cuenta auxiliar `lab.tmp.hash@citas.test`.

## Instrucciones para el agente al retomar

1. Confirmar con `git status`/`git log` en `citas`, `citas-api` y `citas-web` que no hay sorpresas.
2. **Git:**
   - No hay `git` en el PATH; usar el `git.exe` de GitHub Desktop.
   - Commits de `citas-api`/`citas-web`: hacerlos dentro de los contenedores, porque los hooks necesitan `mvn`/`npm`. Usar `git commit -F .git/<archivo>` con el archivo escrito con la herramienta Write, porque PowerShell 5.1 añade un BOM al canalizar.
   - Push de `develop`: autorizado por el usuario, vía el Git Credential Manager de GitHub Desktop.
   - Preguntar antes de subir a `main` o forzar un push.
3. **Docker** (`docker compose ps`). Los contenedores `citas-api-dev` y `citas-web-dev` quedan inactivos (`tail -f /dev/null`), así que hay que levantarlos a mano:
   - Backend: `docker compose exec -e SPRING_PROFILES_ACTIVE=local citas-api-dev mvn spring-boot:run`
   - Frontend: `docker compose exec citas-web-dev npm run dev`. Tras editar `citas-web` hay que reiniciarlo: Vite en Docker/Windows no detecta los cambios.
4. **Pruebas Maven:**
   - La BD de pruebas es persistente. Toda prueba que cree citas `REQUESTED` debe resolverlas en un `@AfterEach`, aunque falle (patrón en `SpecializedDecisionIntegrationTest`).
   - El pool Hikari de pruebas está limitado a 3 en `DatabaseIntegrationSupport`, para no exceder `max_connections`.
   - El equipo va justo de memoria: evitar corridas completas redundantes, porque el hook del commit ya corre la suite.
5. Para S5, usar `EnterPlanMode` antes de escribir código y confirmar con el usuario las decisiones ambiguas: URL y autenticación del webhook, eventos a emitir y credenciales de n8n/Gmail, que configura el usuario y nunca se versionan.
6. Al cerrar cada HU, actualizar la wiki (`contracts.md`, `traceability.md`, `index.md`, `log.md`) y la trazabilidad Scrum (HU + `scrum/README.md`).
