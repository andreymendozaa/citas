# Prompt de continuación — retomar el proyecto FCV Citas

> Pega este archivo completo (o su contenido) como primer mensaje de la próxima sesión con Claude Code para retomar exactamente donde quedó el trabajo.

## Contexto para el agente

Lee primero, en este orden:
1. `CLAUDE.md` (raíz)
2. `AGENTS.md` (raíz)
3. `citas-api/AGENTS.md`
4. `citas-web/AGENTS.md`
5. `citas-api/docs/FCV Dev/llm-wiki/wiki/index.md`

Esos archivos son la fuente de verdad. Este prompt es solo un resumen operativo de continuidad y no los reemplaza.

## Estado al cierre de la sesión del 2026-09-30

**S4 cerrado.** Backend y frontend de los Incrementos 1 y 3 están completos:
- HU-008, HU-009, HU-010, HU-012 y HU-013 en `Completada`.
- HU-029, HU-030, HU-031 y HU-032 en `Completada`.

**Frontend (`citas-web`, rama `develop`).** Se añadieron, sin cambios de contrato ni de backend:
- Pantallas de recuperación y restablecimiento de contraseña. El token puede llegar por `?token=`, que se retira de la URL al cargar.
- Pestañas por rol en el dashboard:
  - USER: Mis citas | Mi perfil.
  - PROFESSIONAL: Agenda | Disponibilidad.
  - ADMIN: Bandeja | Oferta | EPS y planes.
- Agenda Día/Semana con cierre `COMPLETED`/`NO_SHOW`.
- Bandeja unificada `/admin/inbox`, que reemplaza `pending-specialized` en el cliente.
- Historial de estados por cita, visible para los tres roles.

Archivos nuevos en `src/components/`:
- `PasswordRecoveryScreens.tsx`
- `ProfileTab.tsx`
- `InsuranceAdminTab.tsx`
- `ProfessionalAgendaTab.tsx`
- `AdminInboxTab.tsx`
- `AppointmentHistory.tsx`
- `format.ts`
- `s4Screens.test.tsx`

**Evidencia.**
- `npm run lint`, `npm test` (34/34) y `npm run build` en verde.
- Validación manual en Chrome contra el backend en Docker con perfil `local`.

**Documentación en `citas-api`.** Se actualizaron las HU de `docs/FCV Dev/scrum/historias-de-usuario/` y, en la wiki, `contracts.md`, `log.md`, `index.md` y `risks-open-questions.md`.

**Commits.** Todo está empujado a `origin/develop` en los tres repos. El agente puede hacer push de `develop` con el Git Credential Manager de GitHub Desktop (ver memoria `git-exe-location`); antes de subir a `main` o forzar un push, debe preguntar.

**BD de desarrollo.** Durante la validación se aplicó `database/seed-lab-scheduling.sql` y se reasignó localmente la contraseña de las cuentas `lab.*@citas.test`, porque el hash del seed no coincide con la contraseña documentada `Demo1234*`. Queda como riesgo en la wiki. También se creó la cuenta auxiliar `lab.tmp.hash@citas.test` y la cita sintética pasada "LAB: cita pasada por cerrar".

## Qué falta (en orden recomendado)

0. **Requerimientos funcionales cerrados (2026-09-30).** La auditoría y su cierre están en la wiki `traceability.md` y en `scrum/README.md`.
   - **Estado global:** 31 HU `Completada`; RF-01 a RF-19 implementados y probados (Maven 66/66, Vitest 44/44). Las pruebas nuevas corrigieron 4 errores 500 y la edición/eliminación de bloques pasados.
   - **Pendientes:** HU-004/RF-20 (OpenAPI, S5), HU-033 (en progreso) y HU-034 a 036 (n8n, S5/S6).
   - **Mejoras menores fuera de los CA:** editar nombre y duración de especialidades en la UI, y Actuator.
   - **Pendiente de decisión del usuario:** el repositorio raíz `citas` está publicado, en conflicto con la restricción de dos repos públicos.
   - **Entorno:** tras editar `citas-web` hay que reiniciar `npm run dev`, porque Vite en Docker/Windows no detecta los cambios. Las pruebas Maven usan un pool Hikari de 3 para no exceder `max_connections`.
1. **S5**:
   - Swagger/OpenAPI con `springdoc-openapi-starter-webmvc-ui` 2.8.13.
   - Crear `current-state.md` en la raíz.
   - Activar el webhook real hacia n8n Cloud, conectándolo al puerto `Ports.AppointmentEvents` ya preparado y sin tocar `SchedulingJdbcAdapter`.
2. **Deuda visual.** Las pantallas de S4 no tienen referencia Stitch/AI Studio aprobada; se construyeron extendiendo el estilo existente. Hay que decidir si pasan por el flujo `stitch-design-to-frontend`.
3. **Seed de laboratorio.** Corregir `database/seed-lab-scheduling.sql` o `database/reference/README_DB.md` para que la contraseña documentada funcione.
4. **Seguridad, lo hace el usuario:** revocar o dejar expirar el PAT de GitHub usado el 2026-09-29.

## Instrucciones para el agente al retomar

1. Confirmar con `git status`/`git log` en `citas`, `citas-api` y `citas-web` que no hay sorpresas.
2. Verificar Docker (`docker compose ps`). Los contenedores `citas-api-dev` y `citas-web-dev` quedan inactivos (`tail -f /dev/null`), así que hay que levantarlos manualmente:
   - Backend: `docker compose exec -e SPRING_PROFILES_ACTIVE=local citas-api-dev mvn spring-boot:run`
   - Frontend: `docker compose exec citas-web-dev npm run dev`
3. Para S5, usar `EnterPlanMode` antes de escribir código y confirmar con el usuario las decisiones ambiguas (URL y autenticación del webhook, eventos a emitir).
4. Actualizar la wiki y la trazabilidad Scrum al cerrar cada HU.
