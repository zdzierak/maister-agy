# maister-migration — Detailed Workflow Phases & State Schema

## Workflow Phases

### Phase 1: Current State Analysis & Clarifications

**Purpose**: Comprehensive analysis of current system before migration, followed by scope/requirements clarification
**Execute**:
1. Read and execute `../codebase-analyzer/SKILL.md` in main agent context
2. Update state with analysis results
3. Direct - use ask_question for max 5 critical clarifying questions about migration scope, target system, and constraints
4. Save clarifications to `analysis/clarifications.md`

**Output**: `analysis/current-state-analysis.md`, `analysis/clarifications.md`
**State**: Update `migration_context.current_system`, `migration_context.clarifications_resolved`, `migration_context.phase_summaries.current_state_analysis`

→ **AUTO-CONTINUE** — Do NOT end turn, do NOT prompt user. Proceed immediately to Phase 2.

---

### Phase 2: Target State Planning & Gap Analysis

**Purpose**: Define target system and identify migration gaps
**Execute**: `invoke_subagent` - `gap-analyzer` subagent
**Output**: `analysis/target-state-plan.md`
**State**: Update `migration_context.migration_type`, `target_system`, `migration_strategy`, `risk_level`, `breaking_changes`, `migration_context.phase_summaries.gap_analysis`

**Gap Analyzer Tasks**:
1. Define target system from migration description
2. Identify gaps (features to migrate, APIs to adapt, data to transform)
3. Classify migration type (code/data/architecture/general), keeping a type supplied by `--type`
4. Recommend migration strategy (incremental/big-bang/dual-run/phased)
5. External research via `search_web` for version upgrades

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Extract from gap analysis: current system overview, target system, migration type classified, number of gaps identified, recommended strategy, risk level. Format as brief overview then "Continue to migration strategy?"

---

### Phase 3: Migration Requirements & Strategy Specification

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 2 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Gather migration requirements, then create detailed migration specification with rollback procedures
**Execute**:

**Part A — Migration Requirements Gathering (inline)**:
1. Direct - use ask_question for migration-specific requirements (3-5 questions):
   - Migration scope and boundaries (what's in/out of migration)
   - Rollback expectations and downtime tolerance
   - Data migration specifics (if data migration type)
   - Dual-run requirements (if applicable)
   - Existing code/config to preserve
   - Frame as confirmable assumptions: "I assume X, is that correct?"
2. Save gathered requirements to `analysis/requirements.md`

**Part B — Specification Creation (subagent)**:
3. `invoke_subagent` - `specification-creator` subagent

**Context to pass to subagent**: task_path, task_type (migration), task_description, requirements_path (analysis/requirements.md), project_context_paths (INDEX.md + project_doc_paths from state — all discovered project docs), migration_type, current_system, target_system, risk_level, breaking_changes, phase_summaries (current_state_analysis, gap_analysis), html_style_guide_path (for the spec.html companion)

**Output**: `analysis/requirements.md`, `implementation/spec.md`, `analysis/rollback-plan.md`, optionally `analysis/dual-run-plan.md`
**State**: Update `rollback_plan_created`, `dual_run_configured`, `migration_context.phase_summaries.specification`

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Read `implementation/spec.md` and extract: migration strategy chosen, scope boundaries, rollback approach, breaking changes identified, key constraints. Format as brief overview then "Continue to implementation planning?"

---

### Phase 4: Implementation Planning

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 3 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Break migration into task groups with rollback steps
**Execute**: `invoke_subagent` - `implementation-planner` subagent
**Output**: `implementation/implementation-plan.md` with rollback procedures
**State**: Update task groups and dependencies

**Context to pass to subagent**: task_path, task_type (migration), migration_type, task_description, phase_summaries (current_state_analysis, gap_analysis, specification), html_style_guide_path (for the implementation-plan.html companion)

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Read `implementation/implementation-plan.md` and extract: number of task groups, total steps, rollback steps included, key dependencies, execution sequence. Format as brief overview then "Continue to execute migration?"

---

### Phase 5: Migration Execution

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 4 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Execute migration steps with incremental verification

Delegate implementation to the `implementation-plan-executor` skill regardless of task size — it owns wave dispatch, progress tracking, and the work-log; the orchestrator never writes migration code itself.

**INVOKE NOW** — skill `SKILL.md` execution:

**Execute**: Read and execute `../implementation-plan-executor/SKILL.md` in main agent context
**Output**: Implemented migration changes, `implementation/work-log.md`
**State**: Update implementation progress, extract `migration_context.phase_summaries.implementation`

📋 **Standards Reminder**: Review `.maister/docs/INDEX.md` before implementing.

**⚠️ POST-IMPLEMENTATION CONTINUATION** — After the skill completes and returns control:
1. **HTML plan reconciliation** (backstop for syncs missed during waves): if `implementation/implementation-plan.html` exists, for every group whose md checkboxes are all `[x]`, run the executor's idempotent marker-flip command (`sed` flipping `data-step="N\.[0-9]*" class="step todo"` and `data-group="N" class="group todo"` to `done`). VERIFY: when all md steps are checked, `grep -c 'class="step todo"' implementation/implementation-plan.html` must return 0.
2. Read `orchestrator-state.yml` to confirm you are the orchestrator
3. Update state: add Phase 5 to `completed_phases`
4. Proceed to Phase 6

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Extract from `phase_summaries.implementation` and `implementation/work-log.md`: migration steps completed, files changed, test results, rollback readiness status. Format as brief overview then "Continue to verification?"

---

### Phase 6: Verification + Compatibility Testing

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 5 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Verify migration success with compatibility and rollback testing
**Execute**: Read and execute `../implementation-verifier/SKILL.md` in main agent context
**Output**: `verification/implementation-verification.md`, `verification/compatibility-test-results.md`
**State**: Update verification results

**Migration-Specific Checks**:
- Verify old system still works (if dual-run)
- Test rollback procedures (non-destructive)
- Validate data integrity (for data migrations)
- Check performance benchmarks (before/after)

**⚠️ POST-VERIFICATION CONTINUATION** — After the skill completes and returns control:
1. Read `orchestrator-state.yml` to confirm you are the orchestrator
2. Update state: add Phase 6 to `completed_phases`
3. Evaluate verdict: if PASS → Phase 8, if fixable issues → Phase 7, otherwise stop workflow

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Extract from verification results: overall verdict, issue counts by severity, compatibility test results, data integrity status, rollback test results. Format as detailed overview then "Continue to Phase [7 or 8]?"

---

### Phase 7: Migration Issue Resolution (Conditional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 6 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Fix verification issues through direct editing and re-verification
**Execute**: Direct - apply fixes, re-verify
**Output**: Updated code, `verification_context.fixes_applied`
**State**: Update `reverify_count`, `decisions_made`

**Skip if**: verdict = PASS

**Process**:
1. Display detailed issue breakdown grouped by category and severity, listing location, description, and fixability
2. Present all critical + warning issues as a numbered list
3. ask_question — "Which issues should I fix?" with options: "Fix all fixable issues" / "Let me choose specific issues" / "Skip fixes, proceed as-is"
4. Fix selected issues
5. ask_question — "Re-run verification to check fixes?" with options: "Yes, re-run verification" / "No, proceed to next phase"
6. If re-run → re-invoke `implementation-verifier` → return to Step 1
7. Max 3 iterations

**Data Safety Critical**: HALT on any data integrity issue - never auto-fix data problems. Always present data issues to user with rollback option.

**Exit Conditions**:
- ✅ No critical issues remain → Proceed to Phase 8
- ⚠️ Max iterations (3) reached → Ask user: proceed with warnings or rollback
- ❌ Data integrity issues → HALT immediately, recommend rollback

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary: total issues found, issues fixed, issues remaining by severity. Then "Continue to documentation?"

---

### Phase 8: Documentation (Optional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Create migration guide for end users
**Execute**: `invoke_subagent` - `user-docs-generator` subagent
**Output**: `documentation/migration-guide.md`
**State**: Set documentation complete

**Skip if**: `options.docs_enabled = false`

**Documentation Covers**:
- Migration overview and goals
- Prerequisites and preparation steps
- Step-by-step migration procedure
- Rollback procedures
- Troubleshooting common issues

**Before closing the workflow** (whether or not this phase ran — when it is skipped, this step follows the Phase 7 gate): **Reconcile artifacts against disk** — compare every `artifacts[]` entry in state with what actually exists and name every missing path in the summary (`orchestrator-patterns.md` § 10).

→ End of workflow

---

## Domain Context (State Extensions)

Migration-specific fields in `orchestrator-state.yml`:

```yaml
migration_context:
  migration_type: "code" | "data" | "architecture" | "general"
  current_system:
    description: null
    technologies: []
  target_system:
    description: null
    technologies: []
  migration_strategy:
    approach: "incremental" | "big-bang" | "dual-run" | "phased"
    phases: []
  risk_level: null
  breaking_changes: []
  rollback_plan_created: false
  dual_run_configured: false
  clarifications_resolved: false
  phase_summaries:
    # Every entry also carries the shared base shape (orchestrator-patterns.md § 4):
    #   decisions: []   risks: []   artifacts: [{path, label, html}]
    current_state_analysis: {summary: null}
    gap_analysis: {summary: null}
    specification: {summary: null}
    implementation: {summary: null}

external_research:
  performed: false
  category: null
  breaking_changes: []
  migration_guide_url: null

verification_context:
  last_status: null
  issues_found: null
  fixes_applied: []
  decisions_made: []
  reverify_count: 0

orchestrator:
  options:
    html_output: true  # Seeded from .maister/config.yml at init (default true). Gates dashboard + HTML companions.
    docs_enabled: false  # true when `--user-docs` was passed
```

---

## Task Structure

```
.maister/tasks/migrations/YYYY-MM-DD-migration-name/
├── orchestrator-state.yml
├── dashboard.html                    # Operator dashboard (copied plugin asset — never model-generated)
├── dashboard-data.js                 # Dashboard data projection (rewritten per phase/gate)
├── analysis/
│   ├── current-state-analysis.md     # Phase 1
│   ├── target-state-plan.md          # Phase 2
│   ├── requirements.md               # Phase 3
│   ├── rollback-plan.md              # Phase 3
│   └── dual-run-plan.md              # Phase 3 (if dual-run)
├── implementation/
│   ├── spec.md                       # Phase 3
│   ├── spec.html                     # Phase 3 (HTML companion)
│   ├── implementation-plan.md        # Phase 4
│   ├── implementation-plan.html      # Phase 4 (HTML companion)
│   └── work-log.md                   # Phase 5
├── verification/
│   ├── implementation-verification.md    # Phase 6
│   ├── implementation-verification.html  # Phase 6 (HTML companion)
│   └── compatibility-test-results.md     # Phase 6
└── documentation/
    └── migration-guide.md            # Phase 8 (optional)
```

---

## Auto-Recovery

| Phase | Max Attempts | Strategy |
|-------|--------------|----------|
| 1 | 2 | Expand search patterns, prompt user for file paths |
| 2 | 2 | Re-prompt for target details |
| 3 | 2 | Re-gather requirements, re-invoke spec-creator subagent, regenerate rollback plan |
| 4 | 2 | Regenerate with migration constraints |
| 5 | 5 | Fix syntax errors, prompt user on repeated failure |
| 6 | 3 | Fix-then-reverify. **HALT on data integrity issues** |
| 8 | 1 | Generate text-only without screenshots |

---

## Command Integration

Invoked via:
- `/maister-migration [description] [--type=code|data|architecture|general] [--user-docs] [--sequential]` (new)
- `/maister-migration [task-path] [--from=PHASE] [--sequential]` (resume)

Flags:
- `--type=code|data|architecture|general`: Migration category (affects risk focus). One of those four values; any other value stops at initialization before a task directory exists. Absent, Phase 2 classifies the migration. Name technologies in the description — they belong in `current_system` / `target_system`, not in this flag.
- `--user-docs`: Generate the Phase 8 migration guide. Persisted as `orchestrator.options.docs_enabled: true` in `orchestrator-state.yml`. Defaults to off.
- `--from=PHASE`: Resume from specific phase
- `--sequential`: Disable parallel wave dispatch in `implementation-plan-executor`; run one task group at a time. Persisted as `orchestrator.options.sequential: true` in `orchestrator-state.yml`. Defaults to off (parallel waves).

Task directory: `.maister/tasks/migrations/YYYY-MM-DD-task-name/`
