---
name: maister-development
description: >-
  Unified orchestrator for all development tasks. ALWAYS execute when invoked — never skip for 'straightforward' tasks. Phases adapt based on detected task characteristics rather than predetermined types. Use for any development work that modifies code.
---

# Development Orchestrator

Unified workflow for all development tasks — bug fixes, enhancements, and new features. Phases activate based on context and analysis findings, not predetermined task types.

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
3. `references/domain-context-and-handoff.md` — Domain state schema, task directory structure, research/design handoffs, and command flags

### Step 2: Detect Research Context

**If argument is a research folder path** (matches `.maister/tasks/research/*`):
- Auto-detect research folder, extract task description from `research_context.research_question`
- Read research artifacts (see Research-Based Development section below)
- Set `research_reference` in state automatically

**If `--research=<path>` flag provided**:
- Read research artifacts from specified path
- Copy to `analysis/research-context/`
- Set `research_reference` in state

### Step 3: Initialize Workflow

1. **Capture the clock**: run `date -u +"%Y-%m-%dT%H:%M:%SZ"` via `run_command` NOW — you do NOT know the time from context. Every timestamp written this turn (`created`, `updated`, `generated`, `phases[].started`) uses this value. Date-only or `T00:00:00Z` values are the documented failure mode (orchestrator-patterns.md § 4 Timestamp Rule). Re-run `date` in later turns before writing timestamps.
2. **Create Task Items**: Use `update_steps` to publish the workflow phase checklist (up to 12 concise steps; mark Phase 1 `in_progress` and remaining phases `pending`)
3. **Create Task Directory**: `.maister/tasks/development/YYYY-MM-DD-task-name/`
4. **Initialize State**: Create `orchestrator-state.yml` with task info and research reference
5. **Set up Operator Dashboard** (orchestrator-patterns.md § 8) — first read `.maister/config.yml` and set `orchestrator.options.html_output` (default true if the file/key is absent) and `orchestrator.options.mockup_format` (default `html`; read by Phase 4). **When `html_output` is false, SKIP this entire step** — no `dashboard.html`, no `dashboard-data.js`, no browser auto-open — and proceed. Otherwise: copy `../orchestrator-framework/assets/dashboard.html` to the task root as `dashboard.html`, write the initial `dashboard-data.js` (all phases pending), then **auto-open it in the user's browser** (`open` / `xdg-open` / `start` per platform, passing the plain absolute filesystem path — NEVER a hand-built `file://` URL; on failure just print the path — never block). On resume: re-copy `dashboard.html` only if missing; regenerate `dashboard-data.js` from state; then auto-open it in the browser again (same opener as a new task — the OS focuses an already-open tab rather than duplicating).
6. **Discover project documentation**: Read `.maister/docs/INDEX.md` (if exists), extract ALL file paths from the "Project Documentation" section. This includes predefined docs (vision, roadmap, tech-stack, architecture) AND any user-added project docs (e.g., deployment.md, api-strategy.md). Store complete list as `project_context.project_doc_paths` in state.

### Step 4: Ingest Design Context

Mockups and design artifacts become **binding inputs** to implementation when present. Auto-detect from three sources and unify under `analysis/design-context/`. Skip silently when no sources exist — non-UI tasks see no change.

**Source 1 — Product-design task path**: If the argument resolves to a `.maister/tasks/product-design/*` directory (presence of `outputs/product-brief.md` or `analysis/mockups/`):
- Copy `outputs/product-brief.md` → `analysis/design-context/brief.md`
- Copy `analysis/mockups/*` → `analysis/design-context/mockups/`

**Source 2 — Inline mockup references in task description**: Scan the task description for absolute or relative paths ending in `.html`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.pdf`, plus design-tool URLs (Figma, Sketch Cloud, Zeplin):
- For each resolvable local file: copy into `analysis/design-context/mockups/`
- For URLs: append the link to `analysis/design-context/external-links.md` (do not fetch — leave to user)

**Source 3 — Legacy locations** (resumed tasks, mid-flight migrations): If `analysis/visuals/` or `analysis/ui-mockups.md` is populated and `analysis/design-context/` does not yet exist, migrate the legacy contents into `design-context/` (visuals → `mockups/`, `ui-mockups.md` → `ascii/ui-mockups.md`).

**After ingestion** (when `design-context/` was populated):
- Generate `analysis/design-context/INDEX.md` enumerating every screen/component with stable IDs (e.g., `screen:login`, `component:user-card`) inferred from filenames and content. One row per screen/component with: id, source mockup, brief description.
- Set `task_context.design_reference` and `phase_summaries.design` (one-paragraph summary + path to INDEX.md).

**Skip if no sources detected** — proceed to phase execution without `design-context/`.

**Output**:
```
🚀 Development Orchestrator Started

Task: [description]
Directory: [task-path]
Dashboard: open [task-path]/dashboard.html in a browser to monitor progress

Starting Phase 1: Codebase Analysis...
```

---

## Operator Visibility (applies to every phase)

> **Config gate**: these rules assume `options.html_output` is true (read from `.maister/config.yml` at init, default true). When **false**: skip rule 2 entirely (no dashboard — no `dashboard.html`/`dashboard-data.js`, no browser open, no rewrites) and rule 3's companions (do NOT pass `html_style_guide_path`; subagents write md only). Rule 1 (§ 7 TL;DR blocks), rule 4, and `phase_summaries` in state stay active either way.

Cross-cutting rules from `orchestrator-patterns.md` apply throughout this workflow:

1. **Artifact Summary Contract (§ 7)**: every artifact-writing subagent prompt MUST include the contract instruction (artifacts open with TL;DR / Key Decisions / Open Questions / Risks (the writer heading is `## Open Questions / Risks`)). At context extraction, lift `decisions`, `risks`, and `artifacts` into `phase_summaries.[phase]` (shared entry shape, § 4).
2. **Dashboard upkeep (§ 8)**: rewrite `dashboard-data.js` at every phase START (mark it `in_progress` before delegating), **BEFORE firing every exit gate** (register the finished phase's artifacts/summary/decisions/risks so the operator reviews them on the dashboard while answering — status stays `in_progress` until the gate passes), after every phase completion (including skips, with reason), every gate decision, every verification cycle, and at finalization. It is a terse projection of state — never duplicate artifact content into it.
3. **HTML companions (§ 9)**: pass `html_style_guide_path` (absolute path to `../orchestrator-framework/references/html-report-style.md`) to specification-creator, implementation-planner, and e2e-test-verifier. Register returned `html_path` values in `phase_summaries.[phase].artifacts[].html`.
4. **State writes (§ 4 Write Rule)**: update `orchestrator-state.yml` key by key in place, validate it with a re-read after every write, and stop with `ask_question` on a malformed file — never continue on a state file the operator tooling cannot read.

---

## When to Use

Use for **all development tasks**: bug fixes, enhancements, new features, and any work that modifies code.

**DO NOT use for**: Performance optimization, security remediation, migrations, documentation-only, pure refactoring (use specialized orchestrators).

---

## Phase Configuration

| Phase | content | activeForm | Activation |
|-------|---------|------------|------------|
| 1 | "Analyze codebase & clarify requirements" | "Analyzing codebase & clarifying" | Always |
| 2 | "Analyze gaps & clarify scope" | "Analyzing gaps & clarifying scope" | Always |
| 3 | "Write failing test (TDD Red)" | "Writing failing test" | When `has_reproducible_defect` |
| 4 | "Generate UI mockups" | "Generating UI mockups" | When `ui_heavy` |
| 5 | "Gather requirements & create specification" | "Gathering requirements & creating specification" | Always |
| 6 | "Audit specification" | "Auditing specification" | Always (conditional) |
| 7 | "Plan implementation" | "Planning implementation" | Always |
| 8 | "Execute implementation" | "Executing implementation" | Always |
| 9 | "Verify test passes (TDD Green)" | "Verifying test passes" | When Phase 3 was executed |
| 10 | "Prompt verification options" | "Prompting verification options" | Always |
| 11 | "Verify implementation & resolve issues" | "Verifying implementation" | Always |
| 12 | "Run E2E tests" | "Running E2E tests" | When `e2e_enabled` |
| 13 | "Generate user documentation" | "Generating user documentation" | When `user_docs_enabled` |
| 14 | "Finalize workflow" | "Finalizing workflow" | Always |

---

---

## Workflow Phase Execution

**MANDATORY**: Read `references/workflow-phases.md` (relative to this `SKILL.md` directory) using `read_file` and execute every phase in order, honoring all `→ MANDATORY GATE` (`ask_question`) checkpoints, `→ AUTO-CONTINUE` transitions, `invoke_subagent` delegations, and `orchestrator-state.yml` / `dashboard-data.js` updates.

For the `orchestrator-state.yml` domain extension schema, task folder layout, command flags, and research/product-design handoff rules, also read `references/domain-context-and-handoff.md`.
