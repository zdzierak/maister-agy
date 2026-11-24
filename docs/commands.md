# Command Reference

> **Note**: In Google Antigravity, all user-facing Maister commands are packaged as skills in `skills/maister-*/SKILL.md` and exposed automatically as `/maister-*` slash commands in both the Antigravity App and Antigravity CLI (`agy`). Originally adapted from [SkillPanel/maister](https://github.com/SkillPanel/maister) for Claude Code.

## Unified Entry Point

### `/maister-work [input]`

Auto-classifies your task and routes to the appropriate workflow orchestrator. Accepts:

- **No arguments**: Extracts the task from your current conversation context
- **Task description**: `/maister-work "Add user profile page"`
- **Task folder path**: `/maister-work .maister/tasks/development/2026-11-24-user-profile` (resumes)
- **Issue reference / URL**: `/maister-work #42` or `/maister-work https://github.com/org/repo/issues/42`

Invokes the `task-classifier` subagent (`invoke_subagent`) for confidence-scored classification, confirms with you via `ask_question`, and launches the matching orchestrator.

---

## Development

### `/maister-development [description | task-path]`

Starts the unified development workflow (14 adaptive phases) or resumes an existing task. All arguments are optional — when run without a description, Maister extracts it from your current conversation. Pass an existing task path to resume, or pass a completed research / product-design task path to build on it.

| Flag | Description |
|------|-------------|
| `--type=bug\|enhancement\|feature` | Override auto-detected task characteristics |
| `--e2e` / `--no-e2e` | Force or skip runtime browser E2E verification phase |
| `--user-docs` / `--no-user-docs` | Force or skip end-user documentation phase |
| `--audit` / `--no-audit` | Force or skip independent specification audit |
| `--research=PATH` | Start development informed by a completed research task |
| `--sequential` | Disable parallel subagent wave dispatch; execute one task group at a time |
| `--from=PHASE` | Start from or resume at a specific phase |
| `--reset-attempts` | Reset failed attempt counters (resume) |

**Task directory**: `.maister/tasks/development/`
**Resume phases**: `analysis`, `gap`, `spec`, `plan`, `implement`, `verify`

---

## Performance

### `/maister-performance [description | task-path]`

Starts performance optimization with static bottleneck analysis (9 phases) or resumes an existing task. Detects N+1 queries, missing indexes, O(n²) algorithms, blocking I/O, and memory leak patterns, and optionally incorporates profiling artifacts placed in `analysis/user-profiling-data/`.

| Flag | Description |
|------|-------------|
| `--sequential` | Execute implementation task groups sequentially instead of parallel waves |
| `--from=PHASE` | Start from or resume at a specific phase |
| `--reset-attempts` | Reset failed attempt counters (resume) |

**Task directory**: `.maister/tasks/performance/`
**Resume phases**: `analysis`, `specification`, `planning`, `implementation`, `verification`

---

## Migration

### `/maister-migration [description | task-path]`

Starts the migration workflow (8 phases) with mandatory rollback planning, compatibility checks, and optional dual-run support, or resumes an existing migration.

| Flag | Description |
|------|-------------|
| `--type=code\|data\|architecture\|general` | Migration category (auto-classified in Phase 2 when omitted) |
| `--user-docs` | Generate the Phase 8 end-user migration guide |
| `--sequential` | Execute migration task groups sequentially |
| `--from=PHASE` | Start from or resume at a specific phase |
| `--reset-attempts` | Reset failed attempt counters (resume) |

**Task directory**: `.maister/tasks/migrations/`
**Resume phases**: `analysis`, `target`, `spec`, `plan`, `execute`, `verify`, `docs`

---

## Research

### `/maister-research [question | task-path]`

Starts the multi-source research workflow (6 phases) with parallel `information-gatherer` subagents, pattern synthesis, optional solution brainstorming, and C4/MADR architecture design.

| Flag | Description |
|------|-------------|
| `--type=technical\|requirements\|literature\|mixed` | Research methodology type |
| `--brainstorm` / `--no-brainstorm` | Force or skip solution brainstorming phases |
| `--design` / `--no-design` | Force or skip high-level architecture design phase |
| `--from=PHASE` | Start from or resume at a specific phase |
| `--reset-attempts` | Reset failed attempt counters (resume) |

Research output feeds directly into development: `/maister-development .maister/tasks/research/...`

**Task directory**: `.maister/tasks/research/`

---

## Product Design & Mockups

### `/maister-product-design [description | task-path]`

Starts the interactive product/feature design workflow (9 adaptive phases, 0–8) or resumes an existing design. Transforms ideas into structured, layered product briefs through collaborative problem exploration, unbiased alternative generation, iterative section-by-section specification, and visual prototyping.

| Flag | Description |
|------|-------------|
| `--research=PATH` | Import findings from a completed research task |
| `--no-visual` | Skip browser HTML visual companion and use terminal ASCII mockups |
| `--from=PHASE` | Resume from a specific phase |
| `--reset-attempts` | Reset failed attempt counters (resume) |

Design output feeds directly into development: `/maister-development .maister/tasks/product-design/...`

**Task directory**: `.maister/tasks/product-design/`

### `/maister-mockup-studio "<screen or feature>"`

Generates UI mockups standalone for a screen or feature. Discovers your project's real design language first (frontend standards, CSS tokens, Tailwind/theme config, component library) and renders interactive HTML/CSS previews via a zero-dependency local Node.js server (or terminal ASCII when `mockup_format: ascii` is set in `.maister/config.yml` or Node.js is unavailable).

**Task directory**: `.maister/tasks/mockups/`

---

## Reviews & Audits

Standalone read-only review commands powered by specialized subagents:

### `/maister-reviews-code [path] [--scope=quality|security|performance|all]`
Automated code quality, security, and performance analysis with `Critical` / `Warning` / `Info` severity levels.

### `/maister-reviews-pragmatic [path]`
Detects over-engineering, premature abstraction, and infrastructure overkill relative to your project's actual scale.

### `/maister-reviews-reality-check [task-path]`
Validates claimed vs actual completion end-to-end by running tests and checking error/integration paths.

### `/maister-reviews-spec-audit [spec-path | task-path] [--post-implementation]`
Independent senior-auditor review of a specification for ambiguities and gaps (or spec-vs-code drift with `--post-implementation`).

### `/maister-reviews-production-readiness [path] [--target=prod|staging]`
Pre-deployment verification across configuration, monitoring, error handling, performance, security, and rollback safety, returning a GO / DEPLOY WITH CAUTION / NO-GO verdict.

---

## Standards & Initialization

### `/maister-init [--standards-from=PATH]`

Initializes Maister in the workspace:
- Runs the `project-analyzer` subagent (`model: flash`) to inspect tech stack, architecture, and conventions
- Generates `.maister/config.yml`, `.maister/docs/INDEX.md`, `.maister/docs/project/`, and `.maister/docs/standards/`
- Integrates `.maister/docs/INDEX.md` into your workspace `AGENTS.md` (or `GEMINI.md`)
- Runs `/maister-standards-discover --scope=full` to mine project-specific conventions

### `/maister-standards-discover [--scope=SCOPE]`

Auto-discovers coding standards in parallel across config files, source code patterns, project documentation (`README.md`, `CONTRIBUTING.md`, `AGENTS.md`, `GEMINI.md`, ADRs), pull requests, and CI/CD pipelines.

| Flag | Description |
|------|-------------|
| `--scope=full\|quick\|global\|frontend\|backend\|testing\|<custom>` | Discovery scope (default: `full`) |
| `--confidence=N` | Minimum confidence score 0–100 (default: `60`) |
| `--auto-apply` | Auto-apply standards with >= 90% confidence |
| `--skip-external` | Skip GitHub PR and CI/CD analysis |
| `--pr-count=N` | Number of recent merged PRs to analyze (default: `20`) |

### `/maister-standards-update [description] [--from=PATH]`

Creates or updates standards in `.maister/docs/standards/` from conversation context, an explicit rule description, or by syncing diffs from another project (`--from=PATH`).

---

## Quick Commands

Lightweight workflows that operate directly in your codebase without creating `.maister/tasks/` folders:

### `/maister-quick-dev [task description]`
Implements a clear task directly in the main agent while reading `.maister/docs/INDEX.md` + matched standard files and verifying a pass/fail Standards Compliance Checklist afterward.

### `/maister-quick-plan [task description]`
Explores the codebase read-only, folds matched standards and a `## Standards Compliance Checklist` into a reviewable Antigravity implementation plan artifact (`RequestFeedback: true`), waits for approval, and verifies compliance after implementation.

### `/maister-quick-bugfix [bug description]`
Lightweight TDD bug fix: root-cause analysis → complexity escalation check → approved fix plan → failing test (Red gate) → fix + regression check (Green gate) → Standards Compliance Checklist verification.
