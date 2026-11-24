# Workflow Details

> Adapted for Google Antigravity (`agy`) from [SkillPanel/maister](https://github.com/SkillPanel/maister) (originally created for Claude Code).

Maister provides five structured orchestrator workflows. Every orchestrator persists its state in `orchestrator-state.yml`, mirrors live progress via `update_steps` and a self-contained browser dashboard (`dashboard.html`), and pauses at `→ MANDATORY GATE` checkpoints using Antigravity's `ask_question` UI.

---

## Development Workflow (`/maister-development`)

Handles features, enhancements, bug fixes, and refactoring through a 14-phase adaptive pipeline. Phases activate or skip based on task characteristics detected during Gap Analysis rather than rigid upfront labels.

```text
/maister-development
/maister-development "Add two-factor authentication"
/maister-development "Fix login timeout" --type=bug
```

**Flags**: `--type=bug|enhancement|feature`, `--e2e`/`--no-e2e`, `--user-docs`/`--no-user-docs`, `--audit`/`--no-audit`, `--research=PATH`, `--sequential`, `--from=PHASE`, `--reset-attempts`

### Phases

| # | Phase | Applies To |
|---|-------|-----------|
| 1 | Codebase analysis (`codebase-analyzer`) + clarifications | All |
| 2 | Gap analysis (`gap-analyzer`) + scope decision gates | All |
| 3 | TDD Red gate (write failing reproduction test) | When `has_reproducible_defect` |
| 4 | UI mockups (`maister-mockup-studio`: HTML or ASCII) | When `ui_heavy` |
| 5 | Technical approach, requirements & specification (`specification-creator`) | All |
| 6 | Specification audit (`spec-auditor`) | Recommended (skippable) |
| 7 | Implementation planning (`implementation-planner`) | All |
| 8 | Wave-based implementation (`implementation-plan-executor` + parallel `task-group-implementer` subagents) | All |
| 9 | TDD Green gate (verify reproduction test passes) | When Phase 3 ran |
| 10 | Verification options selection | All |
| 11 | Verification (`implementation-verifier`) + fix-and-reverify loop | All |
| 12 | Runtime browser E2E verification (`e2e-test-verifier` via Playwright MCP) | Optional (`--e2e` / `ui_heavy`) |
| 13 | End-user documentation with screenshots (`user-docs-generator`) | Optional (`--user-docs`) |
| 14 | Artifact reconciliation & finalization | All |

### Chaining Research or Product Design into Development

```text
/maister-development .maister/tasks/research/2026-11-24-oauth-research
/maister-development .maister/tasks/product-design/2026-11-24-api-dashboard
```

Research findings (`analysis/research-context/`) and product-design briefs/mockups (`analysis/design-context/`) flow into every downstream phase as binding context without skipping analysis, specification, or verification.

---

## Performance Optimization (`/maister-performance`)

Static code analysis to identify bottlenecks, followed by the specification, planning, parallel wave implementation, and verification pipeline.

```text
/maister-performance
/maister-performance "Optimize dashboard loading time"
```

### Phases

| # | Phase |
|---|-------|
| 1 | Codebase analysis + performance clarifications |
| 2 | Static bottleneck analysis (`bottleneck-analyzer`: N+1 queries, missing indexes, O(n²), blocking I/O, memory leaks) + optional profiling data in `analysis/user-profiling-data/` |
| 3 | Optimization requirements + specification (`specification-creator`) |
| 4 | Specification audit (`spec-auditor`, conditional) |
| 5 | Implementation planning (`implementation-planner`) |
| 6 | Implementation execution (`implementation-plan-executor`) |
| 7 | Verification options |
| 8 | Verification + issue resolution (`implementation-verifier`) |
| 9 | Finalization & runtime profiling guidance |

---

## Migration (`/maister-migration`)

Technology, data, and architecture migrations with mandatory rollback planning, compatibility testing, and data-integrity halt guards.

```text
/maister-migration
/maister-migration "Migrate from REST to GraphQL" --type=architecture
```

### Phases

| # | Phase |
|---|-------|
| 1 | Current state analysis (`codebase-analyzer`) + clarifications |
| 2 | Target state planning + gap analysis (`gap-analyzer`) |
| 3 | Migration requirements + strategy specification (`specification-creator`, includes `rollback-plan.md`) |
| 4 | Implementation planning (`implementation-planner`) |
| 5 | Migration execution (`implementation-plan-executor`) |
| 6 | Compatibility & rollback verification (`implementation-verifier`) |
| 7 | Issue resolution (conditional; halts immediately on data-integrity issues) |
| 8 | Migration guide documentation (`user-docs-generator`, optional `--user-docs`) |

---

## Research (`/maister-research`)

Evidence-based multi-source research with parallel `information-gatherer` subagents, pattern synthesis, optional solution brainstorming, and C4/MADR architecture design.

```text
/maister-research
/maister-research "What authentication approach fits our architecture?" --type=technical
```

### Phases

| # | Phase |
|---|-------|
| 1 | Research foundation: initialize brief → `research-planner` → parallel `information-gatherer` subagents → `research-synthesizer` (`outputs/research-report.md`) |
| 2 | Evaluate brainstorming & architecture design value |
| 3 | Unbiased solution alternatives generation (`solution-brainstormer`) |
| 4 | Sequential interactive convergence across decision areas |
| 5 | High-level C4 architecture & MADR decision log (`solution-designer`) |
| 6 | Artifact reconciliation, summary & handoff to `/maister-development` |

---

## Product Design (`/maister-product-design`)

Interactive workflow for designing features and products before writing code, alternating between exploratory questioning and propose-and-refine convergence.

```text
/maister-product-design
/maister-product-design "Design a dashboard for monitoring API usage"
```

### Phases

| # | Phase | Activation |
|---|-------|------------|
| 0 | Initialize, gather context & detect design characteristics | Always |
| 1 | Unified context synthesis (`codebase-analyzer` + `information-gatherer`) | Always |
| 2 | Problem space exploration & iterative problem statement | Always |
| 3 | User & persona exploration | Greenfield or complex designs |
| 4 | Unbiased design alternatives generation (`solution-brainstormer`) | Always |
| 5 | Interactive direction convergence (`html-companion-writer`) | Always |
| 6 | Section-by-section feature specification (`html-companion-writer`) | Always |
| 7 | Visual prototyping (`maister-mockup-studio`: browser HTML companion or ASCII) | UI-focused designs |
| 8 | Layered product brief assembly & handoff to `/maister-development` | Always |

---

## Task Directory Structure

All orchestrators store artifacts under `.maister/tasks/<type>/YYYY-MM-DD-task-name/`:

```text
2026-11-24-user-auth/
├── orchestrator-state.yml        # Workflow state (pause/resume, phase tracking)
├── dashboard.html                # Static operator dashboard (auto-refreshes every 5s)
├── dashboard-data.js             # Live dashboard state projection
├── analysis/
│   ├── codebase-analysis.md      # Synthesized exploration findings
│   ├── gap-analysis.md           # Current vs desired state & characteristics
│   ├── requirements.md           # Gathered requirements
│   ├── research-context/         # Imported research artifacts (when chained)
│   └── design-context/           # HTML/ASCII mockups, brief, & screen INDEX.md
├── implementation/
│   ├── spec.md / spec.html       # Specification + HTML companion
│   ├── implementation-plan.md    # Task groups with Dependencies & Files to Modify
│   ├── implementation-plan.html  # HTML companion with synced progress markers
│   └── work-log.md               # Chronological wave & standards trail
├── verification/                 # Completeness, test suite, code/pragmatic/reality/E2E reports
└── documentation/                # End-user guide & screenshots (optional)
```

## Internal Machinery Skills

These five skills live in `skills/` and are executed in the main agent context by orchestrators (not invoked directly as user commands):

| Skill | Purpose |
|-------|---------|
| `codebase-analyzer` | Dispatches adaptive parallel `research` subagents and merges findings via `codebase-analysis-reporter` |
| `docs-manager` | Engine behind `.maister/docs/` (loaded by `docs-operator` subagent): file operations, `INDEX.md`, and `AGENTS.md` / `GEMINI.md` integration |
| `implementation-plan-executor` | Computes disjoint parallel waves from `Dependencies` + `Files to Modify`, dispatches `task-group-implementer` subagents, and maintains `work-log.md` and `dashboard-data.js` |
| `implementation-verifier` | Runs `test-suite-runner` followed by parallel specialist review subagents and compiles `implementation-verification.md` + `.html` |
| `orchestrator-framework` | Shared specification of delegation rules, `ask_question` gates, YAML state contracts, HTML report styling, and `dashboard.html` |
