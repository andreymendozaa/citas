# CLAUDE.md — punto de entrada para Claude Code

Este archivo no sustituye ninguna fuente de verdad: solo indica el orden de lectura obligatorio antes de tocar codigo en este workspace.

## Fuente unica de verdad: los AGENTS.md

Cada AGENTS.md es la autoridad operativa de su alcance. Ante cualquier conflicto entre este archivo, un README, un prompt o memoria previa, gana el AGENTS.md correspondiente.

1. AGENTS.md (raiz) - Orquestacion del workspace, limites entre repos, reglas de subagentes, Git y LLM Wiki.
2. citas-api/AGENTS.md - backend (Java 21, Spring Boot, arquitectura hexagonal, MySQL/Flyway). Fuente de verdad para todo cambio dentro de citas-api/.
3. citas-web/AGENTS.md - frontend (React + TypeScript + Vite). Fuente de verdad para todo cambio dentro de citas-web/.

Leer siempre el AGENTS.md del repositorio que se va a tocar antes de planear o editar. Si una tarea es cross-repo, leer los tres.

## Orden de lectura recomendado al iniciar una tarea

1. AGENTS.md (raiz) - alcance y limites.
2. AGENTS.md del repo afectado (citas-api y/o citas-web).
3. README.md, PRD.md, RESTRICCIONES_TECNICAS.md, database/REQUISITOS_NORMALIZACION_3FN.md.
4. citas-api/docs/FCV Dev/llm-wiki/wiki/index.md (LLM Wiki global) para contratos, decisiones y riesgos vigentes.
5. La HU aprobada y su DoD en citas-api/docs/FCV Dev/scrum/historias-de-usuario/.
6. prompts/goal-loop/ para el sprint en curso (S2-S6).

## Reglas que no se repiten aqui

Ninguna regla de arquitectura, seguridad, alcance de repos, convenciones de Git o gobierno de la LLM Wiki se duplica en este archivo: viven unicamente en los AGENTS.md. Este archivo se actualiza solo si cambia el orden de lectura, nunca para copiar contenido de los AGENTS.md.
