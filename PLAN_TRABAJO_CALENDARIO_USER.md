# Plan de trabajo — calendario de agendamiento USER (opción A)

> **Verificación contra los repositorios — 2026-10-04: NO IMPLEMENTADO aquí.** Las casillas marcadas abajo corresponden a otro entorno. En `citas-api`/`citas-web` (`develop`) no existen:
> - `GET /api/v1/availability/days`;
> - `SchedulingService.availableDays`;
> - `scripts/seed-dev-agenda.sql`/`.ps1`;
> - `appointmentsApi.availableDays`;
> - `AvailabilityCalendar.tsx`.
>
> Hoy la reserva USER usa `GET /availability` por fecha dentro del modal existente.
>
> **Decisión del usuario (2026-10-04): fuera del alcance de la entrega; se registra como mejora futura** (ver la wiki `decisions.md`). Ningún CA aprobado lo exige.

Marcar `[x]` al completar. Contrato nuevo: `GET /api/v1/availability/days?locationId&specialtyId&from&to` (USER) → `[{date, slots}]`.

- [x] 1. Backend: `SchedulingService.availableDays` + endpoint + validaciones (400 rango, 403 rol).
- [x] 2. Backend: pruebas Testcontainers.
- [x] 3. Semilla dev `citas-api/scripts/seed-dev-agenda.sql` + `.ps1` (29-sep a 15-oct-2026), ejecutada.
- [x] 4. Frontend: `appointmentsApi.availableDays` + prueba.
- [x] 5. Frontend: `AvailabilityCalendar.tsx` y modal en 3 pasos (especialidad/sede → calendario+horas → confirmación) + pruebas.
- [x] 6. Suites: Maven, lint, Vitest, build.
- [x] 7. Recorrido web USER con datos semilla + verificación MySQL.
- [x] 8. Documentación: contracts.md, log.md, evidencia, HU-021/033, current-state.md; `git diff --check`.
- [x] 9. API y web ejecutándose.
