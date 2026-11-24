---
name: maister-migration
description: >-
  Orchestrates the complete migration workflow from current state analysis through implementation to compatibility verification. Handles technology migrations, platform changes, and architecture pattern transitions with adaptive risk assessment, incremental execution, and rollback planning. Use when migrating technologies, platforms, or architecture patterns.
---

# Migration Orchestrator

Systematic migration workflow from current state analysis to verified migration with rollback capabilities.

## Initialization

**BEFORE executing any phase, you MUST complete these steps:**

### Step 0: Session-reminder conflict resolution (decide ONCE)

Before doing anything else, settle this policy now and do not re-litigate it at any gate:

**`→ MANDATORY GATE` markers fire regardless of session-reminders, permission mode, or prior approval patterns.** Auto / accept-edits / dangerously-skip-permissions modes, reminders saying "work without stopping" / "continue without asking" / "minimize clarifying questions," and compaction summaries showing the user approving every prior gate do NOT exempt you from invoking `ask_question` at a gate. They apply only to your discretionary clarifications.

If you find yourself reasoning "the user has been approving everything, so I can skip this gate" or "auto-mode is on, so I should minimize questions" — that reasoning IS the failure mode. STOP and fire the gate.

Full framework rule: `../orchestrator-framework/references/orchestrator-patterns.md` § 2 and § 2.1.

### Step 1: Load Framework Patterns

**Read the framework reference file NOW using `read_file`:**

1. `../orchestrator-framework/references/orchestrator-patterns.md` — Delegation rules (`invoke_subagent` & skill `SKILL.md` execution), mandatory `ask_question` gates, state schema, `update_steps` initialization, context passing, issue resolution
2. `references/workflow-phases.md` — Complete step-by-step instructions, gates, prompts, and state updates for every phase of this orchestrator (MANDATORY: read this file in full before executing Phase 1)

### Step 2: Initialize Workflow

1. **Capture the clock**: run `date -u +"%Y-%m-%dT%H:%M:%SZ"` via `run_command` NOW — you do NOT know the time from context. Every timestamp written this turn (`created`, `updated`, `generated`, `phases[].started`) uses this value. Date-only or `T00:00:00Z` values are the documented failure mode (orchestrator-patterns.md § 4 Timestamp Rule). Re-run `date` in later turns before writing timestamps.
2. **Validate the flags**: `--type`, when passed, must be one of `code`, `data`, `architecture`, `general`. On any other value, print those four and STOP — do not create the task directory, do not write state. A technology name belongs in the description, not the flag; Phase 2 classifies when the flag is absent. A valid value is recorded as `migration_context.migration_type`. `--user-docs`, when passed, is recorded as `orchestrator.options.docs_enabled: true`.
3. **Create Task Items**: Use `update_steps` to publish the workflow phase checklist (up to 12 concise steps; mark Phase 1 `in_progress` and remaining phases `pending`)
4. **Create Task Directory**: `.maister/tasks/migrations/YYYY-MM-DD-task-name/`
5. **Initialize State**: Create `orchestrator-state.yml` with migration context
6. **Set up Operator Dashboard** (orchestrator-patterns.md § 8) — first read `.maister/config.yml` and set `orchestrator.options.html_output` (default true if the file/key is absent). **When `html_output` is false, SKIP this entire step** — no `dashboard.html`, no `dashboard-data.js`, no browser auto-open — and proceed. Otherwise: copy `../orchestrator-framework/assets/dashboard.html` to the task root as `dashboard.html`, write the initial `dashboard-data.js` (all phases pending, `task.type: "migration"`), then **auto-open it in the user's browser** (`open` / `xdg-open` / `start` per platform, passing the plain absolute filesystem path — NEVER a hand-built `file://` URL; on failure just print the path — never block). On resume: re-copy `dashboard.html` only if missing; regenerate `dashboard-data.js` from state; then auto-open it in the browser again (same opener as a new task — the OS focuses an already-open tab rather than duplicating).
7. **Discover project documentation**: Read `.maister/docs/INDEX.md` (if exists), extract ALL file paths from the "Project Documentation" section — includes predefined docs AND any user-added project docs. Store as `project_context.project_doc_paths` in state.

**Output**:
```
🚀 Migration Orchestrator Started

Task: [migration description]
Directory: [task-path]
Dashboard: open [task-path]/dashboard.html in a browser to monitor progress

Starting Phase 1: Analyze current state...
```

---

## Operator Visibility (applies to every phase)

> **Config gate**: these rules assume `options.html_output` is true (read from `.maister/config.yml` at init, default true). When **false**: skip the Dashboard-upkeep rule entirely (no dashboard files, no browser open, no rewrites) and the HTML-companions rule (do NOT pass `html_style_guide_path`; subagents write md only). The Artifact Summary Contract (§ 7 TL;DR blocks) and `phase_summaries` in state stay active either way.

Cross-cutting rules from `orchestrator-patterns.md` (same as the development orchestrator):

1. **Artifact Summary Contract (§ 7)**: every artifact-writing subagent prompt MUST include the contract instruction (artifacts open with TL;DR / Key Decisions / Open Questions / Risks (the writer heading is `## Open Questions / Risks`)). At context extraction, lift `decisions`, `risks`, and `artifacts` into `phase_summaries.[phase]` — verbatim, never re-summarized.
2. **Dashboard upkeep (§ 8)**: rewrite `dashboard-data.js` at every phase START (mark `in_progress` before delegating), **BEFORE firing every exit gate** (register the finished phase's artifacts/summary/decisions/risks — the operator reviews them on the dashboard while answering; status stays `in_progress` until the gate passes), after every phase completion (including skipped phases, with reason), every gate decision, every verification cycle, and at finalization. Every rewrite starts with `date -u` (one call per turn). It is a terse projection of state — never duplicate artifact content into it.
3. **HTML companions (§ 9)**: pass `html_style_guide_path` (absolute path to `../orchestrator-framework/references/html-report-style.md`) to specification-creator, implementation-planner, and implementation-verifier. Register returned `html_path` values in `phase_summaries.[phase].artifacts[].html` so the dashboard hero cards link HTML first.
4. **icon_hint values** per phase: 1 `analysis`, 2 `analysis`, 3 `spec`, 4 `plan`, 5 `code`, 6 `verify`, 7 `verify`, 8 `docs`.
5. **State writes (§ 4 Write Rule)**: update `orchestrator-state.yml` key by key in place, validate it with a re-read after every write, and stop with `ask_question` on a malformed file — never continue on a state file the operator tooling cannot read.

---

## When to Use

Use for:
- Migrating from one framework/library to another (e.g., Vue 2 → Vue 3, Express → Fastify)
- Changing database platforms (e.g., MySQL → PostgreSQL, MongoDB → DynamoDB)
- Refactoring architecture patterns (e.g., REST → GraphQL, Monolith → Microservices)
- Upgrading major versions with breaking changes

**DO NOT use for**: New features, bug fixes, pure refactoring without technology change.

---

## Core Principles

1. **Analyze Before Migrating**: Understand current system before planning target state
2. **Risk Assessment**: Classify migration type (code/data/architecture) and assess complexity
3. **Incremental Execution**: Support phased migration with rollback points
4. **Rollback Planning**: Document undo procedures for each migration phase
5. **Dual-Run Support**: Enable running old and new systems in parallel during transition

---

## Migration Types

| Type | Keywords | Strategy | Risk Focus |
|------|----------|----------|------------|
| **Code** | framework, library, upgrade | Incremental or phased | Breaking changes, API differences |
| **Data** | database, schema, data migration | Dual-run (zero downtime) | Data integrity, checksums |
| **Architecture** | REST→GraphQL, monolith→microservices | Dual-run or phased | Compatibility, rollback |

---

## Phase Configuration

| Phase | content | activeForm | Agent/Skill |
|-------|---------|------------|-------------|
| 1 | "Analyze current state" | "Analyzing current state" | codebase-analyzer |
| 2 | "Plan target state and gaps" | "Planning target state and gaps" | gap-analyzer |
| 3 | "Gather requirements & create migration strategy" | "Gathering requirements & creating migration strategy" | Direct + specification-creator (subagent) |
| 4 | "Plan implementation" | "Planning implementation" | implementation-planner (subagent) |
| 5 | "Execute migration" | "Executing migration" | implementation-plan-executor |
| 6 | "Verify and test compatibility" | "Verifying and testing compatibility" | implementation-verifier |
| 7 | "Resolve verification issues" | "Resolving verification issues" | Direct (conditional) |
| 8 | "Generate documentation" | "Generating documentation" | user-docs-generator (optional) |

---

---

## Workflow Phase Execution

**MANDATORY**: Read `references/workflow-phases.md` (relative to this `SKILL.md` directory) using `read_file` and execute every phase in order, honoring all `→ MANDATORY GATE` (`ask_question`) checkpoints, `→ AUTO-CONTINUE` transitions, `invoke_subagent` delegations, and `orchestrator-state.yml` / `dashboard-data.js` updates.
