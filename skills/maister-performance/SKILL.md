---
name: maister-performance
description: >-
  Orchestrates performance optimization workflows using static code analysis to identify bottlenecks (N+1 queries, missing indexes, O(n^2) algorithms, blocking I/O, memory leaks). Accepts optional user-provided profiling data. Reuses standard specification, planning, implementation, and verification phases.
---

# Performance Orchestrator

Static-analysis-first performance optimization workflow. Identifies bottlenecks by reading code, then uses the standard specification/planning/implementation/verification pipeline to fix them.

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
2. **Create Task Items**: Use `update_steps` to publish the workflow phase checklist (up to 12 concise steps; mark Phase 1 `in_progress` and remaining phases `pending`)
3. **Create Task Directory**: `.maister/tasks/performance/YYYY-MM-DD-task-name/`
4. **Create Subdirectories**: `analysis/`, `analysis/user-profiling-data/`, `implementation/`, `verification/`
5. **Initialize State**: Create `orchestrator-state.yml` with performance context
6. **Set up Operator Dashboard** (orchestrator-patterns.md § 8) — first read `.maister/config.yml` and set `orchestrator.options.html_output` (default true if the file/key is absent). **When `html_output` is false, SKIP this entire step** — no `dashboard.html`, no `dashboard-data.js`, no browser auto-open — and proceed. Otherwise: copy `../orchestrator-framework/assets/dashboard.html` to the task root as `dashboard.html`, write the initial `dashboard-data.js` (all phases pending, `task.type: "performance"`), then **auto-open it in the user's browser** (`open` / `xdg-open` / `start` per platform, passing the plain absolute filesystem path — NEVER a hand-built `file://` URL; on failure just print the path — never block). On resume: re-copy `dashboard.html` only if missing; regenerate `dashboard-data.js` from state; then auto-open it in the browser again (same opener as a new task — the OS focuses an already-open tab rather than duplicating).
7. **Discover project documentation**: Read `.maister/docs/INDEX.md` (if exists), extract ALL file paths from the "Project Documentation" section — includes predefined docs AND any user-added project docs. Store as `project_context.project_doc_paths` in state.

**Output**:
```
Performance Orchestrator Started

Task: [performance issue description]
Directory: [task-path]
Dashboard: open [task-path]/dashboard.html in a browser to monitor progress

Starting Phase 1: Codebase Analysis...
```

---

## Operator Visibility (applies to every phase)

> **Config gate**: these rules assume `options.html_output` is true (read from `.maister/config.yml` at init, default true). When **false**: skip the Dashboard-upkeep rule entirely (no dashboard files, no browser open, no rewrites) and the HTML-companions rule (do NOT pass `html_style_guide_path`; subagents write md only). The Artifact Summary Contract (§ 7 TL;DR blocks) and `phase_summaries` in state stay active either way.

Cross-cutting rules from `orchestrator-patterns.md` (same as the development orchestrator):

1. **Artifact Summary Contract (§ 7)**: every artifact-writing subagent prompt MUST include the contract instruction (artifacts open with TL;DR / Key Decisions / Open Questions / Risks (the writer heading is `## Open Questions / Risks`)). At context extraction, lift `decisions`, `risks`, and `artifacts` into `phase_summaries.[phase]` — verbatim, never re-summarized.
2. **Dashboard upkeep (§ 8)**: rewrite `dashboard-data.js` at every phase START (mark `in_progress` before delegating), **BEFORE firing every exit gate** (register the finished phase's artifacts/summary/decisions/risks — the operator reviews them on the dashboard while answering; status stays `in_progress` until the gate passes), after every phase completion (including skipped phases, with reason), every gate decision, every verification cycle, and at finalization. Every rewrite starts with `date -u` (one call per turn). It is a terse projection of state — never duplicate artifact content into it.
3. **HTML companions (§ 9)**: pass `html_style_guide_path` (absolute path to `../orchestrator-framework/references/html-report-style.md`) to specification-creator, implementation-planner, and implementation-verifier. Register returned `html_path` values in `phase_summaries.[phase].artifacts[].html` so the dashboard hero cards link HTML first.
4. **icon_hint values** per phase: 1 `analysis`, 2 `analysis`, 3 `spec`, 4 `verify`, 5 `plan`, 6 `code`, 7 `verify`, 8 `verify`, 9 `done`.
5. **State writes (§ 4 Write Rule)**: update `orchestrator-state.yml` key by key in place, validate it with a re-read after every write, and stop with `ask_question` on a malformed file — never continue on a state file the operator tooling cannot read.

---

## When to Use

Use for:
- Application slow (response time issues, high latency)
- Need systematic bottleneck identification and resolution
- Want static code analysis for performance anti-patterns
- Have user-provided profiling data to act on
- Database query optimization needed
- Algorithm or I/O inefficiencies suspected

**DO NOT use for**: New features, bug fixes, refactoring without performance goals.

---

## Core Principles

1. **Static Analysis First**: Read code to detect patterns. Don't try to run profiling tools.
2. **User Data Welcome**: Incorporate user-provided profiling data when available
3. **Reuse Standard Phases**: Use proven specification/planning/implementation/verification pipeline
4. **Conservative Estimates**: Provide improvement ranges, not false precision
5. **Practical Optimizations**: Focus on patterns the agent CAN detect and fix

---

## Phase Configuration

| Phase | content | activeForm | Agent/Skill |
|-------|---------|------------|-------------|
| 1 | "Analyze codebase" | "Analyzing codebase" | codebase-analyzer |
| 2 | "Analyze performance bottlenecks" | "Analyzing performance bottlenecks" | bottleneck-analyzer |
| 3 | "Gather requirements & create specification" | "Gathering requirements & creating specification" | specification-creator |
| 4 | "Audit specification" | "Auditing specification" | spec-auditor (conditional) |
| 5 | "Plan implementation" | "Planning implementation" | implementation-planner |
| 6 | "Execute implementation" | "Executing implementation" | implementation-plan-executor |
| 7 | "Prompt verification options" | "Prompting verification options" | Direct |
| 8 | "Verify implementation & resolve issues" | "Verifying implementation" | implementation-verifier |
| 9 | "Finalize workflow" | "Finalizing workflow" | Direct |

---

---

## Workflow Phase Execution

**MANDATORY**: Read `references/workflow-phases.md` (relative to this `SKILL.md` directory) using `read_file` and execute every phase in order, honoring all `→ MANDATORY GATE` (`ask_question`) checkpoints, `→ AUTO-CONTINUE` transitions, `invoke_subagent` delegations, and `orchestrator-state.yml` / `dashboard-data.js` updates.
