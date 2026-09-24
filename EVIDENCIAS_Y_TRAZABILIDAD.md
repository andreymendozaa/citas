# Evidencias y trazabilidad para evaluación final

La calificación se realiza al finalizar S6, pero el historial debe permitir reconstruir el progreso.

## Evidencia mínima por sesión

| Sesión | Evidencia mínima |
|---|---|
| S2 | commit backend + commit frontend; AGENTS; Scrum specs; baseline ejecutable |
| S3 | commits; tests; hook FAIL/PASS; secreto ficticio bloqueado |
| S4 | commits; logs Builder/Verifier; goal/loop; MVP |
| S5 | commit; WF-001 JSON; evidencia MCP; riesgos residuales |
| S6 | commit final; WF-002 JSON; validaciones; merge/main estable; sustentación |

## Regla Git
- desarrollo en `develop`;
- `main` representa únicamente puntos que el estudiante considera estables;
- no exigir merge por sesión;
- no hacer squash/rebase destructivo que borre el progreso antes de la evaluación.

## Plantilla de registro

```text
Sesión:
Repo:
Branch:
Commit hash:
HU abordadas:
Criterios completados:
Pruebas ejecutadas:
Qué quedó pendiente:
Evidencia adicional:
```

## n8n evaluable
Los JSON exportados deben abrir/importar sin depender de secretos embebidos. Las credenciales se configuran en n8n y nunca deben formar parte del JSON/repositorio en texto claro.

## Registro técnico S4 — Incremento 0 en curso · 2026-09-24

- Repositorios: `citas-api` y `citas-web`, rama `develop`.
- Evidencia backend: `mvn test` contra MySQL de desarrollo con 16 pruebas verdes; incluye reserva concurrente con un único `APPROVED` y un conflicto, aprobación/rechazo con historial, retención/liberación de slots, edición/eliminación de bloques futuros, profesional/especialidad inactivos y autorización de rutas S3.
- Evidencia frontend: `npm run lint`, `npm test` (13 pruebas) y `npm run build` verdes; se cubren payload REST de reserva y de bloques, mensajes `403`/`409`, el conflicto de disponibilidad y la confirmación `APPROVED` del modal.
- Builder/Verifier: Prompt 0 (núcleo y concurrencia) PASS: 14 pruebas Maven y 11 Vitest; Prompt 1 (contrato de bloques) PASS: 12 Vitest; Prompt 2 (DTO ADMIN pendiente) PASS: 14 Maven y 12 Vitest; Prompt 3 (confirmación USER) PASS: 13 Vitest; Prompt 4 (hook frontend) PASS; Prompt 5 (reglas de agenda) PASS: 16 pruebas Maven.
- Calidad: el hook backend bloqueó un secreto sintético y luego pasó con la suite Maven. El hook frontend bloqueó `src/secret-hook-demo.env`, el archivo fue retirado y luego pasó con lint, pruebas y build. `citas-web/Dockerfile.dev` instala Git para que el detector staged sea reproducible.
- Pendiente: ampliar cobertura de roles, decisiones, historial y flujos manuales cross-repo antes de cerrar HU o declarar el Incremento 0 completado.
