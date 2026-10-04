# Sustentación técnica — Plataforma de Citas FCV

**Estudiante:** Andrey Mendoza · **Fecha de corte:** 2026-10-04 · **Programa:** FCV Training Lab (S2–S6)

**Repositorios** (rama de trabajo `develop`, todos publicados y sincronizados con GitHub):

| Repo | URL | Rol | Commits en `develop` |
|---|---|---|---|
| `citas-api` | github.com/andreymendozaa/citas-api | Backend: Java 21, Spring Boot 3.5, MySQL 8.4 | 34 |
| `citas-web` | github.com/andreymendozaa/citas-web | Frontend: React 19, TypeScript, Vite, Tailwind | 12 |
| `citas` | github.com/andreymendozaa/citas | Orquestación del workspace: planes, guías, prompts, estado | 21 |

---

## 1. Resumen ejecutivo (1 minuto)

Plataforma web de **agendamiento de citas médicas** para dos sedes de la FCV: el Hospital Internacional de Colombia (HIC) y el Instituto Cardiovascular (ICV). Tiene tres roles:

- **USER (paciente):** se registra, busca disponibilidad, reserva, cancela, reprograma y consulta su historial.
- **PROFESSIONAL:** publica bloques de disponibilidad, consulta su agenda y cierra atenciones (COMPLETED / NO_SHOW).
- **ADMIN:** gestiona especialidades, profesionales, EPS y planes, y aprueba o rechaza citas especializadas y reprogramaciones en una bandeja unificada.

Se suman **tres automatizaciones n8n** (recordatorios, notificación por cambio de estado y resumen diario) y un **agente conectado por MCP**.

| Indicador | Resultado |
|---|---|
| Historias de usuario | **36 de 36 `Completada`** |
| Requisitos funcionales del PRD | **RF-01 a RF-20 implementados y probados** |
| Pruebas backend (Maven + MySQL) | **72/72**, estables también con datos ajenos (LOOP_03) |
| Pruebas frontend (Vitest) | **44/44**, con lint y build en verde |
| Contrato REST | OpenAPI 3 publicado: 38 rutas, `/v3/api-docs` y Swagger UI |
| Automatizaciones | WF-001 y WF-002 obligatorios + WF-003 bonus, todos validados; WF-002 publicado |

---

## 2. Problema y alcance (PRD)

El PRD define 20 requisitos funcionales:

| RF | Capacidad | RF | Capacidad |
|---|---|---|---|
| 01 | Registro de usuario | 11 | Cita general (auto-aprobada) |
| 02 | Login y sesión JWT | 12 | Cita especializada (requiere ADMIN) |
| 03 | Recuperación de contraseña | 13 | Mis citas |
| 04 | Perfil y afiliación | 14 | Cancelación |
| 05 | Catálogos fijos | 15 | Reprogramación |
| 06 | Catálogos configurables (EPS, planes, especialidades) | 16 | Agenda visible al profesional |
| 07 | Gestión de profesionales | 17 | Cierre de atención |
| 08 | Agenda del profesional (bloques) | 18 | Bandeja administrativa |
| 09 | Duración por especialidad (30/60 min) | 19 | Auditoría de estados |
| 10 | Consulta de disponibilidad | 20 | REST entre frontend y backend |

**Fuera de alcance por decisión documentada:**
- calendario mensual para USER ("opción A");
- edición de especialidades en la UI;
- agregado diario por estado (brecha B4).

Están registrados como mejoras futuras en la wiki (`decisions.md`, `risks-open-questions.md`).

---

## 3. Arquitectura

```
┌──────────────┐  REST/JSON (/api/v1, JWT)   ┌───────────────────────────────┐        ┌──────────┐
│  citas-web   │ ──────────────────────────► │           citas-api           │ ─────► │ MySQL 8.4│
│ React + Vite │ ◄────────────────────────── │  hexagonal: domain/application│  JDBC  │ Flyway   │
└──────────────┘   (sin Express ni BFF)      │  ports / adapters             │        └──────────┘
                                             └──────────────┬────────────────┘
                                                            │ webhook post-commit (Bearer, sin PII)
                                                            ▼
                         ┌─────────────────────────────────────────────────────┐
                         │ n8n (instancia del trainer) WF-001 · WF-002 · WF-003 │──► Gmail (OAuth2)
                         └─────────────────────────────────────────────────────┘
                                     ▲  MCP (OAuth)
                                     └── Claude Code (agente)
```

### Backend: arquitectura hexagonal

| Capa / paquete | Responsabilidad |
|---|---|
| `domain` | Reglas puras, sin Spring ni JPA (p. ej. `Identity`) |
| `application` | Casos de uso (`SchedulingService`, `AuthService`, `ProfileService`) y **puertos** (`Ports`) |
| `adapter.web` | Controladores REST: solo traducen HTTP; errores como Problem Details |
| `adapter.persistence` | JDBC/JPA y transacciones de reserva |
| `adapter.security` | JWT access/refresh |
| `adapter.events` | Puerto de salida a n8n (`N8nWebhookAppointmentEvents`, no-op si no hay URL configurada) |
| `adapter.mailbox` | Buzón local de recuperación (perfil `local`) |
| `config` | Seguridad, CORS, OpenAPI y guardia anti-CSRF del login |

### Datos (3FN, Flyway)

| Migración | Contenido |
|---|---|
| `V1__identity` | Usuarios, roles, refresh tokens |
| `V2__scheduling_core` | Sedes, especialidades, profesionales y asignaciones, bloques, **slots de 30 min**, citas, historial de estados |
| `V3__reschedule_requests` | Solicitudes de reprogramación con estados propios |
| `V4__password_reset_tokens` | Tokens de un solo uso (hash SHA-256) |
| `V5__insurance_regimes_seed` | Regímenes de afiliación de referencia |

Las migraciones aplicadas no se editan. Los catálogos fijos se siembran por seed y todos los datos de laboratorio son sintéticos.

---

## 4. Reglas de negocio clave (lo que más se evalúa)

1. **Slots de 30 minutos:** un bloque del profesional se divide en franjas de 30 min. Una especialidad de 60 min ocupa **2 slots consecutivos**.
2. **Reserva concurrente segura:** la asignación de slots es una actualización condicional dentro de la transacción. Dos reservas simultáneas producen **exactamente un** `APPROVED` y un `409` (prueba `concurrentReservationsProduceExactlyOneAppointmentAndOneConflict`).
3. **General vs. especializada:**
   - general → `APPROVED` de inmediato (fuente `SYSTEM`);
   - especializada → `REQUESTED` con los slots **retenidos**, hasta que el ADMIN la aprueba (`APPROVED`) o la rechaza (`REJECTED`, con motivo obligatorio, liberando los slots).
4. **Reprogramación:** el USER solicita una nueva franja, que queda **retenida** mientras la solicitud está `PENDING`. El ADMIN aprueba (intercambia slots) o rechaza (libera la retenida).
5. **Bloques:** solo fechas **futuras**, solo en sedes asignadas al profesional y **sin solapes** (`409 Bloque solapado`). No se editan ni eliminan bloques pasados o con citas.
6. **Cierre de atención:** solo el profesional dueño, solo sobre citas `APPROVED` ya transcurridas → `COMPLETED` / `NO_SHOW`.
7. **Auditoría:** toda transición queda en `appointment_status_history` con su fuente (`SYSTEM` / `USER` / `ADMIN` / `PROFESSIONAL`) y motivo. Es visible por rol con *ownership*: un `404` no distingue "no existe" de "no autorizado".
8. **Zona horaria de negocio:** `America/Bogota`.

---

## 5. Seguridad

- **JWT:** access token de 15 min, guardado **solo en memoria** en el navegador; refresh token en **cookie HttpOnly** que **rota** en cada uso; el logout revoca la sesión.
- **Contraseñas:** hash adaptativo. La recuperación es anti-enumeración (siempre `202`) y usa token de un solo uso; restablecer la contraseña revoca todos los refresh tokens.
- **CORS explícito** y **guardia anti-CSRF** en login/refresh/logout (`X-Requested-With`, `Origin` permitido).
- **Autorización por rol y *ownership*** en cada ruta (`@PreAuthorize` + filtros SQL por dueño).
- **Secretos:** solo en variables de entorno; `.env` está ignorado por Git y los `.env.example` no contienen valores reales.
- **Hooks `pre-commit`** en ambos repos:
  - corren las pruebas y bloquean el commit si fallan;
  - detectan patrones de secreto.
  - En S3 se demostró el bloqueo con un **secreto ficticio** y luego el commit permitido.

---

## 6. Contrato REST (HU-004 / RF-20)

- **OpenAPI 3** con springdoc 2.8.13:
  - `GET /v3/api-docs` y **Swagger UI** en `/swagger-ui/index.html`;
  - copia versionada en `citas-api/docs/openapi/openapi-v1.json` (38 rutas `/api/v1/**`);
  - esquema `bearerAuth`.
- **`GET /actuator/health`** es público y no muestra detalles.
- **Errores homogéneos** (Problem Details):
  - `400` validación;
  - `401` no autenticado;
  - `403` rol o guardia;
  - `404` inexistente o ajeno;
  - `409` conflicto de slot, transición inválida o bloque solapado.
- El **frontend** consume REST directo con `VITE_API_URL`, sin Express ni BFF.

---

## 7. Frontend

Hecho en React 19 + TypeScript + Vite + Tailwind, a partir del prototipo importado (`portal-de-citas.zip`). La navegación son pestañas por rol dentro del dashboard:

| Rol | Pantallas |
|---|---|
| Público | Login, registro, recuperación y restablecimiento de contraseña |
| USER | *Mis citas* (filtros, cancelar, reprogramar, historial), *Agendar cita* (modal: tipo, especialidad, sede, fecha → profesional y franja → confirmación), *Mi perfil* (teléfono, afiliación EPS/plan) |
| PROFESSIONAL | *Agenda* (día/semana, cierre de atención), *Disponibilidad* (crear, editar y eliminar bloques) |
| ADMIN | *Bandeja* unificada (especializadas + reprogramaciones), *Oferta* (especialidades, profesionales, asignaciones), *EPS y planes*, historial |

**Deuda aceptada:** las pantallas de S3/S4 extienden el estilo del prototipo y no tienen aprobación formal en Stitch/AI Studio (HU-033, decisión del estudiante documentada).

---

## 8. Calidad y verificación

| Evidencia | Detalle |
|---|---|
| Pruebas backend | 20 clases, **72 casos** de integración contra MySQL real: reglas de slots 30/60, doble reserva concurrente, autorización por rol, ciclo de vida completo, catálogos, OpenAPI y webhook |
| Pruebas frontend | 6 archivos, **44 casos** (clientes REST, pantallas por rol, modal de reserva, auth) |
| Red → Green | Se escribieron pruebas que **fallaron primero** y destaparon bugs reales: 4 errores 500 por filas inexistentes o ajenas, bloques pasados editables, concurrencia de slots y deduplicación de n8n |
| Hooks | `pre-commit` corre la suite completa en cada commit (72/72 en todos los commits de S5/S6) |
| Auditoría Scrum | Criterio estricto: un CA es PASS **solo** con prueba automatizada o propiedad estructural (auditoría del 2026-09-30) |

---

## 9. Trabajo agéntico: GOALs, LOOPs y Builder/Verifier

- **Ciclos guiados de S4:** se ejecutaron con Builder y Verifier, registrados por prompt en `EVIDENCIAS_Y_TRAZABILIDAD.md` ("Registro técnico S4"). Por ejemplo, Prompt 0 de concurrencia PASS 14 Maven / 11 Vitest, … Prompt 8 PASS 19 Maven. Las guías están en `prompts/goal-loop/` (GOAL_01/02, LOOP_01/02).
- **LOOP_03 (reto independiente, diseñado por el estudiante)** sobre **pruebas frágiles frente a la BD de pruebas persistente** (`citas-api/docs/FCV Dev/evidence/LOOP_03-pruebas-fragiles.md`):
  - **Disparador:** suites que fallaban o modificaban datos ajenos cuando la BD tenía pendientes de otras corridas.
  - **Iteración 0 (Red):** con datos ajenos sembrados, 71/72.
  - **Hallazgo latente:** `AuthIntegrationTest` pasaba de casualidad y **rechazaba una solicitud ajena** cuando esta quedaba primera.
  - **Iteración 1:** el Builder corrige solo `src/test`.
  - **Resultado:** el Verifier obtiene **72/72 dos veces seguidas** y los datos ajenos quedan intactos.
  - **Presupuesto:** 1 de 5, sin escalamiento.
  - **Por qué no bastaba un prompt:** el fallo dependía del estado acumulado y del orden de los datos; solo apareció al endurecer el escenario.

---

## 10. Automatizaciones n8n (S5/S6)

Instancia del trainer, **cuenta compartida** con otros estudiantes: todos los recursos llevan el prefijo `Andrey` y no se tocan los ajenos. JSON exportados y saneados en `citas-api/automations/n8n/`; el script `check-workflows.mjs` verifica que no haya ids de credencial, URLs, correos ni tokens.

| Workflow | Disparador | Qué hace | Evidencia |
|---|---|---|---|
| **WF-001 Recordatorios** (HU-034) | Cada hora | Login ADMIN sintético → `upcoming` → filtra la ventana de **24 h** → quita datos personales → **descarta los ya recordados** → Gmail. Rama de error "API no disponible" que hace fallar la ejecución (no hay éxito silencioso) | #171 envía, #172 no duplica, #169 rama de error |
| **WF-002 Notificación por cambio de estado** (HU-035) | **Webhook** desde la API (post-commit) | Valida el payload (202/400), Header Auth (403 sin token), **deduplica por `eventId`**, 5 ramas: especializada aprobada/rechazada, cancelación, reprogramación aprobada/rechazada → Gmail | **Publicado**. 5 eventos reales de la API (#129–#133) y duplicado descartado (#128) |
| **WF-003 Resumen diario** (HU-036, bonus) | 06:00 Bogotá | `APPROVED` del día por sede y especialidad, pendientes de la bandeja e incidencias → Gmail HTML | #329 con un día simulado: HIC 2, ICV 1; 1 + 1 pendientes |

**Contrato del webhook (versión `1.0`, sin PII):**
- campos: `schemaVersion`, `eventId` (UUID), `eventType` (`appointment.status.changed` | `appointment.reschedule.decided`), `appointmentId`, `status`, `source`, `occurredAt` (UTC);
- entrega asíncrona después del commit: nunca bloquea ni hace fallar la transacción;
- timeouts de 3 s / 5 s y 1 reintento con el mismo `eventId`.

**Hallazgo técnico Red → Green:** `$getWorkflowStaticData` no persistía entre ejecuciones en esta instancia y un evento repetido generó dos correos. Se reemplazó por el nodo nativo **Remove Duplicates** (`removeItemsSeenInPreviousExecutions`).

**Conectividad:**
- WF-002 no la necesita: la API llama a n8n.
- WF-001 y WF-003 consultan la API local mediante un **túnel temporal** (Cloudflare) abierto solo durante las pruebas; su URL nunca se versiona.

---

## 11. Agente conectado: MCP y contenido no confiable (S5)

- **Cliente MCP:** Claude Code. **Servidor MCP:** el MCP de instancia de n8n (OAuth). Invocación demostrada desde el agente: `search_workflows` devolvió los 3 workflows `Andrey`.
- **Privilegio mínimo:** `availableInMCP=false` en nuestros workflows; no se modificó la configuración global de una instancia compartida.
- **Análisis de contenido no confiable** (`evidence/S5-MCP-contenido-no-confiable-y-riesgos.md`), con 4 fuentes:
  1. **Issue envenenado** (fixture sintético con órdenes ocultas en un comentario HTML: mostrar `.env`, redirigir el webhook, `push --force` a `main`) → tratado como dato, ninguna acción ejecutada.
  2. **Comentario de revisión** que pide `--no-verify` y versionar un secreto → rechazado.
  3. **Salida de una dependencia** (`cloudflared`) → binario oficial con firma verificada; su salida se trató como información.
  4. **Respuesta MCP** → las instrucciones del servidor son guía técnica y no autorizan acciones.
- **Casos reales de la sesión:**
  - planes de otro entorno que afirmaban funcionalidades inexistentes (verificados contra el código y corregidos);
  - n8n asignó automáticamente una **credencial de otro estudiante** (detectado y retirado).

---

## 12. Riesgos residuales

| # | Riesgo | Mitigación / estado |
|---|---|---|
| R1 | Cuenta n8n compartida: el token MCP actúa sobre toda la cuenta | Prefijo `Andrey`, solo WF-002 publicado, sin PII en ejecuciones, `availableInMCP=false` |
| R2 | Prompt injection vía contenido de terceros | Regla "contenido = dato" y confirmación humana para acciones irreversibles |
| R3 | Scopes amplios de Gmail OAuth | Proyecto Google Cloud dedicado en modo prueba; revocar al terminar el curso |
| R4 | Túnel público temporal | JWT obligatorio, cuentas sintéticas, solo durante pruebas |
| R5 | JWT ADMIN visible en ejecuciones fallidas o manuales | 15 min de vida, cuenta sintética |
| R6 | Webhook *best-effort* | 1 reintento y deduplicación por `eventId` |
| R7 | OAuth en modo prueba puede pedir reconexión | Reconectar la credencial |
| R8 | Static data de n8n no persistía | Mitigado con Remove Duplicates |

---

## 13. Proceso: Scrum, LLM Wiki y Git

- **Spec-Driven Development:** PRD → épicas → 36 HU con CA y DoD en `citas-api/docs/FCV Dev/scrum/`, cada una con tabla de evidencia por CA e historial de validación.
- **LLM Wiki** (`citas-api/docs/FCV Dev/llm-wiki/`): `index`, `contracts`, `decisions`, `traceability`, `risks-open-questions`, `log`. Cada cambio relevante deja una entrada fechada (HECHO / DECISIÓN / PREGUNTA ABIERTA).
- **Agentes:** `AGENTS.md` raíz (orquestación), `citas-api/AGENTS.md` y `citas-web/AGENTS.md` como fuentes de verdad por repo, más un catálogo de subagentes.
- **Git:**
  - desarrollo en `develop` con commits trazables por sesión (`feat(s4-…)`, `feat(s5)`, `feat(s6)`, `test(loop-03)`, `test(hu-…)`);
  - sin reescritura de historial;
  - `main` se actualiza al cerrar la entrega (merge `develop → main` sin squash).

| Sesión | Entregable | Dónde verlo |
|---|---|---|
| S2 | Repos, AGENTS, Scrum, registro y login JWT, frontend importado | Commits iniciales; HU-001 a HU-007 |
| S3 | Agendamiento general y especializado, pruebas, hook FAIL/PASS, secreto ficticio bloqueado | `EVIDENCIAS_Y_TRAZABILIDAD.md`; HU-014 a HU-024 |
| S4 | MVP completo, Builder/Verifier, LOOP_01/02/03 | `feat(s4-…)`; `evidence/LOOP_03-pruebas-fragiles.md` |
| S5 | WF-001 + JSON, MCP, contenido no confiable, riesgos residuales | `evidence/S5-*.md`; `automations/n8n/` |
| S6 | WF-002 + JSON y validaciones, WF-003 bonus, cierre | `evidence/S6-WF-002-notificaciones.md`; HU-035/036 |

---

## 14. Guion de demostración en vivo (10–12 minutos)

**Preparación:**
- `docker compose up -d`;
- arrancar la API y la web (ver `current-state.md`);
- Gmail del buzón de laboratorio abierto.

Las cuentas sintéticas están en `prompts/goal-loop/CONTINUAR_PROXIMA_SESION.md`.

1. **Contrato:** abrir `http://localhost:8080/swagger-ui/index.html` y mostrar `bearerAuth` y las rutas por rol.
2. **PROFESSIONAL** (`lab.cardio`): *Disponibilidad* → crear un bloque futuro en ICV. Mostrar el **409 de solape** si se cruza con otro bloque.
3. **USER** (`lab.paciente`):
   - *Agendar cita* de Medicina General → queda `APPROVED` de inmediato.
   - Cardiología → queda `REQUESTED`.
   - Intentar la misma franja otra vez → `409`.
4. **ADMIN** (`lab.admin`): *Bandeja* → aprobar la especializada.
   - **Mostrar el correo** que llega por WF-002 (n8n → Gmail) y la ejecución en n8n (`result=sent`).
5. **USER:** cancelar una cita → llega el correo de cancelación. Abrir el **historial** de la cita (fuentes USER/ADMIN/SYSTEM).
6. **PROFESSIONAL:** *Agenda* → cierre `COMPLETED` / `NO_SHOW` de una cita pasada.
7. **n8n:**
   - mostrar los 3 workflows y la deduplicación (#127 sent / #128 duplicate);
   - mostrar el JSON saneado en el repo.
8. **Calidad:** ejecutar `mvn test` (72/72) o mostrar el hook en un commit; mostrar LOOP_03.
9. **Seguridad:** abrir el fixture del issue envenenado y explicar por qué el agente no actúa.

---

## 15. Preguntas probables y respuestas

| Pregunta | Respuesta corta |
|---|---|
| ¿Por qué arquitectura hexagonal? | El dominio y los casos de uso no dependen de Spring ni de la BD. El webhook de n8n se conectó como un **adaptador nuevo** detrás de un puerto ya existente, sin tocar el núcleo |
| ¿Cómo evitan la doble reserva? | Actualización condicional de slots dentro de la transacción; probado con hilos concurrentes: un `APPROVED` y un `409` |
| ¿Por qué el refresh en cookie y el access en memoria? | La cookie HttpOnly protege el refresh de XSS; el access de corta vida en memoria evita persistirlo en el navegador. Hay guardia anti-CSRF en las rutas que usan la cookie |
| ¿Qué pasa si n8n está caído? | La transacción ya se confirmó (post-commit, asíncrono). Hay 1 reintento y el evento se pierde sin afectar la cita (riesgo R6 documentado) |
| ¿Cómo evitan correos duplicados? | `eventId` UUID en el emisor y nodo Remove Duplicates en n8n (#128 = duplicate) |
| ¿Por qué no se usó `$getWorkflowStaticData`? | Se probó y no persistía en esta instancia (bug reproducido en la ejecución #121); se reemplazó y se volvió a validar |
| ¿Dónde están los secretos? | En `.env` (ignorado por Git) y en el gestor de credenciales de n8n; los JSON llevan marcadores `<<...>>` |
| ¿Qué falta o qué mejorarías? | Calendario mensual de disponibilidad, edición de especialidades en la UI, agregado diario por estado, aprobación visual en Stitch y un proyecto n8n por estudiante |
| ¿Por qué hay tres repos si la regla dice dos? | `citas-api` y `citas-web` son los entregables. `citas` es el repo de orquestación (guías, planes, estado), mantenido por decisión consciente y sin secretos |

---

## 16. Anexos (rutas)

- Estado operativo y arranque: `current-state.md`.
- Wiki: `citas-api/docs/FCV Dev/llm-wiki/wiki/index.md`.
- HU y tablero: `citas-api/docs/FCV Dev/scrum/` (`README.md` con el estado auditado).
- Evidencias S5/S6/LOOP_03: `citas-api/docs/FCV Dev/evidence/`.
- Workflows n8n: `citas-api/automations/n8n/` (+ `check-workflows.mjs`).
- Contrato OpenAPI: `citas-api/docs/openapi/openapi-v1.json`.
- Scripts de laboratorio: `citas-api/scripts/loop03-seed-foreign-data.sql`, `citas-api/scripts/hu036-simulacion-dia.sql`.
- Planes de n8n y S3: `PLAN_IMPLEMENTACION_FLUJOS_N8N.md`, `PLAN_CIERRE_AGENDAMIENTO_S3.md`, `PLAN_TRABAJO_CIERRE_S3.md`, `PLAN_TRABAJO_CALENDARIO_USER.md`.
