# Maister SDLC Workflows & Standards Rules

Maister provides structured, standards-aware Software Development Lifecycle (SDLC) workflows for Google Antigravity. Follow these standing rules whenever Maister is active.

## 1. Project Standards Discovery (`.maister/docs/INDEX.md`)

When the workspace contains `.maister/docs/INDEX.md`:
1. **Read `.maister/docs/INDEX.md` first** before planning, specifying, or writing code — even for direct requests outside `/maister-*` workflows.
2. **Read the matched standard files** referenced by `INDEX.md` (under `.maister/docs/standards/` and `.maister/docs/project/`) that apply to the files or domain you touch. Reading `INDEX.md` alone is not sufficient.
3. **Continuous discovery**: When implementation enters a new area mid-task (e.g., auth, database migrations, forms, error handling), check `INDEX.md` again and read newly applicable standards before coding.
4. **Standards evolution**: When a recurring convention or review pattern emerges that is not yet documented, briefly suggest capturing it via `/maister-standards-update`.

## 2. Respecting `/maister-*` Workflow Invocations

- When the user invokes any `/maister-*` slash command or skill, **read and execute that skill's `SKILL.md` as your FIRST action**.
- Never bypass a requested workflow because a task looks "simple" or "straightforward". Complexity assessment belongs to the workflow itself.
- **Don't run full orchestrator workflows inside `/plan` mode**: Maister orchestrators (`/maister-development`, `/maister-performance`, `/maister-migration`, `/maister-research`, `/maister-product-design`) write specifications, state files, and plans under `.maister/tasks/`. Run them in `auto` or `accept-edits` mode; use `/maister-quick-plan` when you want lightweight read-only planning with standards enforcement.

## 3. Mandatory Orchestrator Phase Gates (`ask_question`)

- Every `→ MANDATORY GATE` checkpoint in a Maister orchestrator **MUST call `ask_question`** and wait for the user's response before marking the phase completed or advancing.
- This rule overrides `auto` / `accept-edits` mode heuristics ("minimize clarifying questions") and overrides `ask_question`'s general "skip for trivial yes/no" guidance: always present concrete workflow choices (with `(Recommended)` on the recommended first option).
- Prior user approvals across earlier gates or compacted history never grant permission to skip subsequent `→ MANDATORY GATE` checkpoints.

## 4. Antigravity Delegation Mechanics (Skills vs Subagents)

- **Executing internal skills** (`codebase-analyzer`, `maister-mockup-studio`, `implementation-plan-executor`, `implementation-verifier`): Read the target skill's `SKILL.md` file in the main agent context and execute its steps directly (so it can spawn subagents and interact with the user), then return to the calling orchestrator phase.
- **Spawning subagents** (`invoke_subagent`): Launch specialized Maister subagents (`gap-analyzer`, `specification-creator`, `implementation-planner`, `task-group-implementer`, `code-reviewer`, etc.) via `invoke_subagent(TypeName="<agent-name>", Role="...", Prompt="...")`.
- **Asynchronous wakeup**: `invoke_subagent` runs asynchronously in the background. To run one subagent (or a parallel wave/batch of subagents), emit all `invoke_subagent` calls for that batch in a **single turn**, then **end your turn without polling** — Antigravity automatically resumes your turn when the subagent completion messages arrive. Wait until all subagents in a parallel batch have reported back before advancing.
- **Progress visibility**: Keep `orchestrator-state.yml` on disk as the persistent source of truth for pause/resume, and mirror high-level workflow progress in the UI using `update_steps` (up to 12 concise steps).

## 5. User-Confirmed Rollback & Artifact Anchoring

- **Never automatically rollback or revert code changes** (`git reset --hard`, `git checkout .`, `git stash`, `git clean`) without explicit user confirmation via `ask_question`. Analyze root causes, check for simple config/setup fixes, and present options (`(Recommended) Try suggested fix`, `Rollback changes`, `Let me investigate`).
- **Task directory artifact anchoring**: Save all workflow artifacts (analysis, specs, plans, HTML companions, work-logs, verification reports, screenshots) strictly inside `.maister/tasks/<workflow-type>/<YYYY-MM-DD-task-name>/` — never scatter workflow artifacts into project `src/`, `docs/`, or repository root.
