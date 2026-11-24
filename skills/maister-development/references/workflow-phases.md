# maister-development — Detailed Workflow Phases

## Workflow Phases

### Phase 1: Codebase Analysis & Clarifications

**Purpose**: Comprehensive codebase exploration followed by scope/requirements clarification
**Execute**:
1. Read and execute `../codebase-analyzer/SKILL.md` in main agent context
2. Update state with analysis results
3. Direct - use ask_question for max 5 critical clarifying questions
4. Save clarifications to `analysis/clarifications.md`
**Output**: `analysis/codebase-analysis.md`, `analysis/clarifications.md`
**State**: Update `task_context.risk_level`, `phase_summaries.codebase_analysis`, `task_context.clarifications_resolved`

→ **AUTO-CONTINUE** — Do NOT end turn, do NOT prompt user. Proceed immediately to Phase 2.

---

### Phase 2: Gap Analysis & Scope Clarification

**Purpose**: Compare current vs desired state, detect task characteristics, then resolve scope/approach decisions
**Execute**:
1. `invoke_subagent` - `gap-analyzer` subagent
2. **Extract and store structured data from gap-analyzer result**:
   a. Read `task_characteristics` from gap-analyzer output — 5 fields: `has_reproducible_defect`, `modifies_existing_code`, `creates_new_entities`, `involves_data_operations`, `ui_heavy`
   b. Write all 5 fields to `orchestrator-state.yml` at `task_context.task_characteristics`
   c. Read `risk_level` from output and write to `task_context.risk_level`
   d. Extract phase summary (1-2 sentences) and write to `phase_summaries.gap_analysis`
   e. **SELF-CHECK**: "Did I read the 5 task_characteristics from the gap-analyzer output and write them to state? Let me re-read `orchestrator-state.yml` to verify the values match the gap-analyzer output."

**⛔ DECISION GATE** (mandatory — do NOT skip):
- Parse `decisions_needed` from gap-analyzer output
- If `decisions_needed.critical` OR `decisions_needed.important` is non-empty:
  - MUST use `ask_question` — every decision is its own single-select question with its own option set (never flattened into a single question's option list). Critical decisions: one call each with full context. Important decisions: may be grouped as up to 4 separate questions within one call (orchestrator-patterns.md § 3 Decision Gate Pattern)
- If both are empty: Note "No scope decisions needed" in state

**SELF-CHECK** before continuing: "Did the gap-analyzer return `decisions_needed` items? If yes, did I invoke `ask_question`? If I skipped this, STOP and go back."

3. Save scope clarifications to `analysis/scope-clarifications.md`
4. **Derive optional phase defaults** from the characteristics now in state, and write both values explicitly (`true` or `false`, never left `null`):
   - `options.e2e_enabled` = `ui_heavy`
   - `options.user_docs_enabled` = `ui_heavy` OR `creates_new_entities`
   - Command flags (`--e2e`, `--no-e2e`, `--user-docs`, `--no-user-docs`) override the derived value
   - **SELF-CHECK**: "Did I write `e2e_enabled` and `user_docs_enabled` to state? Let me re-read `orchestrator-state.yml` to verify they match the derivation above." Phases 12 and 13 run only when these are true — a missed write drops them silently.

**Output**: `analysis/gap-analysis.md`, `analysis/scope-clarifications.md` (conditional)
**State**: Update `task_context.task_characteristics`, `task_context.scope_expanded`, `options.e2e_enabled`, `options.user_docs_enabled`, `phase_summaries.gap_analysis`

**Context to pass**: Risk level, codebase summary, key files, clarifications, project_doc_paths (from state)

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

The Phase 2 exit gate **always** invokes `ask_question`. The branching is over *which questions get asked*, not whether to ask:
1. If `decisions_needed.critical` or `.important` is non-empty → present the DECISION GATE questions first (see DECISION GATE block above)
2. Then **always** ask the executive-summary routing question (Phase 3 / 4 / 5 based on `task_characteristics`) shown below

Empty `decisions_needed` skips step 1 only. Step 2 is unconditional. There is no path through Phase 2 that bypasses `ask_question`.

**ANTI-PATTERN — DO NOT DO THIS:**
- ❌ "The UI change is small/simple, skipping Phase 4..." — STOP. If `ui_heavy` is true, Phase 4 runs. The gap-analyzer made this assessment, not you.
- ❌ "No new screens needed, just a component..." — STOP. `ui_heavy` is a signal from the gap-analyzer. Do NOT override it with your own complexity judgment.

ask_question - Display executive summary before asking. Read `analysis/gap-analysis.md` and extract: task type detected, risk level, key characteristics enabled (TDD gates, UI mockups), the `e2e_enabled` and `user_docs_enabled` values now in state, scope decisions made (if any). Then read `task_context.task_characteristics` from `orchestrator-state.yml` and determine the next phase:
- If `has_reproducible_defect` is true → ask "Continue to Phase 3: TDD Red Gate?"
- If `ui_heavy` is true → ask "Continue to Phase 4: UI Mockup Generation?"
- Otherwise → ask "Continue to Phase 5: Technical Approach, Requirements & Specification?"

---

### Phase 3: TDD Red Gate (Conditional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 2 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Write a failing test that reproduces the defect
**Execute**: Direct - write test, verify it FAILS
**Output**: `implementation/tdd-red-gate.md`, failing test file
**State**: Update `tdd_red_passed: true`

**Skip if**: `task_characteristics.has_reproducible_defect` is false (not set by gap-analyzer)

**Critical**: Test MUST fail before implementation (proves defect exists)

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - "TDD red gate complete. Continue to Phase 4?"

---

### Phase 4: UI Mockup Generation (Conditional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Generate UI mockups (HTML by default, ASCII when configured) showing UI integration
**Execute**: Read and execute `../maister-mockup-studio/SKILL.md` in main agent context
**Output**: HTML → `analysis/design-context/mockups/*.html`; ASCII → `analysis/design-context/ascii/ui-mockups.md`. Both append entries to `analysis/design-context/INDEX.md`.
**State**: Update `phase_summaries.ui_mockups`, `phase_summaries.design`, and `task_context.design_resources` (from mockup-studio's discovery)

**Skip if**:
- `task_characteristics.ui_heavy` is false, OR
- `analysis/design-context/mockups/` is already populated (Step 4 ingested external mockups — no need to regenerate)

**Invoke mockup-studio** with:
- `task_path`: this task directory
- `output_subdir`: `analysis/design-context/mockups`
- `format`: `orchestrator.options.mockup_format` (default `html`; mockup-studio auto-falls back to `ascii` when Node is unavailable)
- `iteration`: `single` (one generation pass — the Phase 4 gate below handles approve/revise)
- `emit_index_rows`: `true` (append stable-ID rows to `design-context/INDEX.md` for downstream `Visual References`)
- `context`: gap analysis, scope decisions, component choices, `analysis/design-context/INDEX.md` path (if exists from Step 4)

mockup-studio runs design-resource discovery first (binding standards/tokens/components), then renders. Record its returned `format_used`/`notes` in `phase_summaries.ui_mockups` (e.g. an html→ascii fallback). On the gate's "revise", re-invoke mockup-studio.

**Companion-server lifecycle (HTML path — CRITICAL for operator review):** the Phase 4 gate below is where the operator actually reviews the mockups, and that gate fires AFTER mockup-studio returns. So the live gallery MUST still be up at the gate. mockup-studio (Step 7) is instructed to leave the server running in `iteration: single` mode — do NOT shut it down before the gate, and never `POST /shutdown` yourself between generation and the gate. When mockup-studio reports a live gallery URL (e.g. `http://localhost:3847`), **include that URL verbatim in the gate question** so the operator knows where to look and can click through every screen (gallery grid → each screen → prev/next → ⊞ Gallery). Only AFTER the operator approves (the gate resolves to "continue") do you tear the companion down: `curl -s -X POST http://localhost:${port}/shutdown`. On "revise", leave it running — re-invoking mockup-studio reuses the same server (it also auto-restores screens from the on-disk manifest if it was stopped). If the HTML companion never came up (ASCII fallback, or browser/port failure), skip the URL and just reference the saved mockup files.

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - "UI mockups complete — review the live gallery at [companion URL] (click any card → screen → prev/next). Continue to Phase 5?"

---

### Phase 5: Technical Approach, Requirements & Specification

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**⛔ ROUTING GUARD**: Read `task_context.task_characteristics` from `orchestrator-state.yml`. If `has_reproducible_defect` is true and Phase 3 is NOT in `completed_phases` → STOP, execute Phase 3 first. If `ui_heavy` is true and Phase 4 is NOT in `completed_phases` → STOP, execute Phase 4 first.

**Purpose**: Resolve technical decisions, gather specification requirements, then create comprehensive specification
**Execute**:

**Part A — Technical & Architecture Clarification (inline, conditional)**:
1. If complex task with multiple approaches: Direct - use ask_question for 3-5 technical questions
2. If multiple valid architectural approaches exist: Present 2-3 approaches via ask_question. The chosen approach is passed to specification-creator so the spec is written with the decided architecture.
3. Save to `analysis/technical-clarifications.md` (conditional)

**Skip technical clarification if**: Simple task, risk_level = low, no multiple approaches detected

**Part B — Requirements Gathering (inline)**:
3. Direct - use ask_question for specification requirements:
   - Adaptive question count based on description length:
     - Brief (<30 words): 6-8 questions
     - Standard (30-100 words): 4-6 questions
     - Detailed (>100 words): 2-3 focused questions
   - Frame as confirmable assumptions: "I assume X, is that correct?"
   - REQUIRED questions (always include):
     1. **User Journey**: How will users discover/access this? Which personas? How fits existing workflows?
     2. **Existing Code Reuse**: Similar features, UI components, backend patterns to reference?
     3. **Visual Assets**: Any mockups, wireframes, screenshots? Place in `analysis/design-context/mockups/` (or reference paths inline — Step 4 auto-ingests them)
4. Check for visual assets in `analysis/design-context/` (single source of truth — populated by Step 4 ingestion and/or Phase 4 ASCII generation):
   - If `design-context/INDEX.md` exists: note for subagent context (mockup files become binding inputs)
   - If user provides new mockups during this phase: place them in `analysis/design-context/mockups/`, regenerate `INDEX.md`
   - If not found and non-UI task: skip visual asset processing
5. Save gathered requirements to `analysis/requirements.md` with: initial description, Q&A from all rounds, similar features identified, visual assets and insights, functional requirements summary, reusability opportunities, scope boundaries, technical considerations

**Part C — Specification Creation (subagent)**:

Delegate spec writing to the `specification-creator` subagent (`invoke_subagent`) regardless of task size — the orchestrator coordinates and never writes spec.md itself, so the spec gets the subagent's reusability search and a clean context.

**INVOKE NOW** — `invoke_subagent` call:

6. `invoke_subagent` - `specification-creator` subagent

**Context to pass to subagent**: task_path, task_description, task_characteristics, requirements_path (analysis/requirements.md), project_context_paths (INDEX.md + project_doc_paths from state — all discovered project docs), risk_level, phase_summaries (codebase_analysis, gap_analysis, clarifications, scope_clarifications, ui_mockups, design), research_context (if any), design_reference (if any — points spec-creator to `analysis/design-context/` for mockups and brief), html_style_guide_path (for the spec.html companion)

**Output**: `analysis/technical-clarifications.md` (conditional), `analysis/requirements.md`, `implementation/spec.md`
**State**: Update `task_context.tech_clarified`, `task_context.architecture_decision`, `phase_summaries.specification`

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Read `implementation/spec.md` and extract: spec title, scope boundaries (what's included and excluded), number of key requirements, architecture approach chosen (if any), assumptions made. Format as brief overview then "Continue to specification audit?"

---

### Phase 6: Specification Audit (Recommended)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 5 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Independent review of specification before implementation
**Execute**: `invoke_subagent` - `spec-auditor` subagent
**Output**: `verification/spec-audit.md`
**State**: Update `options.spec_audit_enabled`

**Recommended**: Always. Present spec audit as the recommended default. User can skip if they choose.

ask_question - "Run specification audit? (Recommended)" with "Yes, run audit (Recommended)" as first option

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Read `verification/spec-audit.md` and extract: overall verdict (pass/pass-with-concerns/fail), issue counts by severity, top 1-2 critical findings if any. Format as brief overview then "Continue to implementation planning?"

---

### Phase 7: Implementation Planning

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 6 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Break specification into implementation steps

Delegate planning to the `implementation-planner` subagent (`invoke_subagent`) regardless of task size — the orchestrator never writes implementation-plan.md itself.

**INVOKE NOW** — `invoke_subagent` call:

**Execute**: `invoke_subagent` - `implementation-planner` subagent
**Output**: `implementation/implementation-plan.md`
**State**: Update task groups and dependencies

**Context to pass to subagent**: task_path, task_description, task_characteristics, phase_summaries (specification, gap_analysis, codebase_analysis, design), research_context (if any), design_reference (if any — when `analysis/design-context/INDEX.md` exists, planner MUST enumerate every screen/component, map task groups to them via the required `Visual References` field, and produce `implementation/visual-coverage.md` proving every screen is covered by ≥1 group), html_style_guide_path (for the implementation-plan.html companion)

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Read `implementation/implementation-plan.md` and extract: number of task groups, total implementation steps, key dependencies between groups, estimated complexity. Format as brief overview then "Continue to implementation?"

---

### Phase 8: Implementation

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 7 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Execute the implementation plan

Delegate implementation to the `implementation-plan-executor` skill regardless of task size — it owns wave dispatch, progress tracking, and the work-log; the orchestrator never writes code itself.

**INVOKE NOW** — skill `SKILL.md` execution:

**Execute**: Read and execute `../implementation-plan-executor/SKILL.md` in main agent context
**Output**: Implemented code, `implementation/work-log.md`
**State**: Update implementation progress, extract phase_summaries.implementation

**⚠️ POST-IMPLEMENTATION CONTINUATION** — After the skill completes and returns control:

The executor returning ends Phase 8 and nothing more. The plan's last task group is a group inside Phase 8 whatever it is called ("Finalization", "push readiness") — it is never Phase 14. What comes next is the Phase 8 exit gate below, then Phase 9 or Phase 10.

1. **HTML plan reconciliation** (backstop for syncs missed during waves): if `implementation/implementation-plan.html` exists, for every group whose md checkboxes are all `[x]`, run the executor's idempotent marker-flip command (`sed` flipping `data-step="N\.[0-9]*" class="step todo"` and `data-group="N" class="group todo"` to `done`). VERIFY: when all md steps are checked, `grep -c 'class="step todo"' implementation/implementation-plan.html` must return 0 — a non-zero count means unflipped markers remain; flip them before continuing.
2. Read `orchestrator-state.yml` to confirm you are the orchestrator
3. Update state: add Phase 8 to `completed_phases`
4. Evaluate conditional: if `task_characteristics.has_reproducible_defect` AND Phase 3 in `completed_phases` → Phase 9, else → Phase 10

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary before asking. Extract from `phase_summaries.implementation` and `implementation/work-log.md`: task groups completed, files changed, test results from incremental runs, any known issues or deferred items. Format as brief overview then "Continue to verification?"

---

### Phase 9: TDD Green Gate (Conditional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 8 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Verify the failing test now passes
**Execute**: Direct - run the test written in Phase 3
**Output**: `implementation/tdd-green-gate.md`
**State**: Update `tdd_green_passed: true`

**Skip if**: Phase 3 was not executed

**Critical**: Test MUST pass (proves defect is fixed)

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - "TDD gate passed. Continue to Phase 10?"

---

### Phase 10: Verification Options Prompt

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Determine which verification checks to run using tiered decision matrix
**Execute**: Direct - display plan, confirm/adjust via ask_question
**Output**: Updated state with all verification options
**State**: Set `options.code_review_enabled`, `options.pragmatic_review_enabled`, `options.reality_check_enabled`, `options.production_check_enabled`, `options.e2e_enabled`, `options.user_docs_enabled`, `options.skip_test_suite`
**Auto-set**: `skip_test_suite: true` only when the executor's final `work-log.md` entry records the full test suite as passed; otherwise `skip_test_suite: false`, so verification runs it. Cleared before re-verification if fixes are applied.

**Step 1**: Display the verification plan:
```
Verification Plan:
  Obligatory (always run):
    ✓ Completeness check
    ✓ Test suite (skipped when it passed during implementation — re-enabled after fixes; otherwise runs)

  Recommended (adjustable):
    ✓ Code review — quality and security analysis
    ✓ Pragmatic review — detects over-engineering
    ✓ Reality check — validates work solves the problem
    ✓ Production readiness — deployment readiness checks

  Conditional:
    [✓/—] E2E browser testing — [reason]
    [✓/—] User documentation — [reason]
```

**Step 2** (3 questions):

**Q1** (always): ask_question (multi-select) — "Which standard verifications to run?"
Options: "Code review (Recommended)", "Pragmatic review (Recommended)", "Reality check (Recommended)", "Production readiness (Recommended)". All pre-selected.

**Q2** (ASK when `options.e2e_enabled` or `task_characteristics.ui_heavy` is true, or the `--e2e` flag was given; SKIP only otherwise or when `--no-e2e` was given): ask_question — "Enable E2E browser verification?" Options: "Yes (Recommended)", "No, skip".

**Q3** (ASK when `options.user_docs_enabled`, `ui_heavy`, or `creates_new_entities` is true, or the `--user-docs` flag was given; SKIP only otherwise or when `--no-user-docs` was given): ask_question — "Generate user documentation?" Options: "Yes (Recommended)", "No, skip".

Write each answer to state as an explicit `true`/`false` — Phase 14 reads these to decide whether Phases 12 and 13 were owed.

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

---

### Phase 11: Verification & Issue Resolution

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 10 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Comprehensive implementation verification with fix-then-reverify cycles
**Output**: `verification/implementation-verification.md`, optional code-review/pragmatic/reality reports, updated `implementation/work-log.md`
**State**: Update verification results, `verification_context`

**Execute**:

**Step 1**: Invoke Read and execute `../implementation-verifier/SKILL.md` in main agent context

**Step 2**: Display detailed issue breakdown grouped by category and severity:
```
Verification Results:
  Critical ([N]):
    - [category]: [description] — [file:line] [fixable/manual]
    ...
  Warning ([N]):
    - [category]: [description] — [file:line] [fixable/manual]
    ...
  Info ([N]):
    - [description] (listed for awareness, not actionable)
```

**Step 3**: Gate on verification status:
- `status: passed` → skip to Post-Verification Continuation
- `status: passed_with_issues` or `failed` → enter user-driven fix loop (Step 4)

**Step 4**: User-driven fix loop (max 3 iterations):
1. Present all critical + warning issues as a numbered list
2. ask_question — "Which issues should I fix?" with options:
   - "Fix all fixable issues" (convenience default)
   - "Let me choose specific issues" (user picks by number)
   - "Skip fixes, proceed as-is"
3. Fix selected issues, log each to `verification_context.fixes_applied`
4. After fixes applied: set `skip_test_suite: false` (code changed, tests must re-run)
5. ask_question — "Re-run verification to check fixes?" with options:
   - "Yes, re-run verification" → re-invoke `implementation-verifier` → return to Step 2
   - "No, proceed to next phase"
6. Update `verification_context.reverify_count`

**Exit conditions**:
- No critical issues remain → proceed
- User explicitly chooses "Skip fixes, proceed as-is" or "No, proceed to next phase" → proceed with issues logged
- Max 3 iterations reached → ask_question: "Proceed with known issues?" / "Stop workflow"
- **MUST NOT proceed with unresolved critical issues unless user explicitly approves**

**⚠️ POST-VERIFICATION CONTINUATION** — After issue resolution completes:
1. **Canonical report check**: `verification/implementation-verification.md` + `.html` MUST reflect the FINAL post-fix verdict before leaving this phase. If fixes were applied and the canonical report still shows the pre-fix state (regardless of whether re-checks were run via the full verifier skill or individual subagents writing `*-reverify.md` side files), re-invoke `implementation-verifier` (or have it recompile Phase 3) so the report and companion are rewritten with a "Fix & Re-Verification History" section. A stale pre-fix report is a phase-exit violation.
2. Read `orchestrator-state.yml` to confirm you are the orchestrator
3. Update state: add Phase 11 to `completed_phases`
4. Proceed to Phase 12

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - Display executive summary: total issues found, issues fixed, issues remaining by severity. Then "Continue to Phase 12?"

---

### Phase 12: E2E Testing (Optional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from Phase 11 in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

> **⚠ Serialization rule**: Phases 12 and 13 share the Playwright MCP browser instance. They MUST run strictly sequentially. Do NOT dispatch the Phase 12 Task call and the Phase 13 Task call in the same assistant message, even when both are enabled. Wait for Phase 12 to return, honor the `→ MANDATORY GATE` / `ask_question` gate below, then start Phase 13. Concurrent dispatch will corrupt both browser sessions.

**Purpose**: Runtime browser verification with screenshots (via Playwright MCP tools, not test file generation)
**Execute**: `invoke_subagent` - `e2e-test-verifier` subagent
**Prompt must include**: task_path (absolute), spec_path, base_url, html_style_guide_path (for the HTML companion reports). If `analysis/design-context/mockups/` exists, also include `design_context_path` so the verifier performs an LLM-judged structural visual-fidelity comparison and writes `verification/visual-fidelity.md`. Report saves to `{task_path}/verification/e2e-verification-report.md`.
**Output**: `verification/e2e-verification-report.md` (+ `.html` companion), screenshots, `verification/visual-fidelity.md` (+ `.html` companion) (when mockups present — report-only, never gates completion)
**State**: Update E2E results; on success mark Phase 12 in `completed_phases` (Phase 13 reads this as a precondition).

**Skip if**: `options.e2e_enabled = false`

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - "E2E complete. Continue to Phase 13?"

---

### Phase 13: User Documentation (Optional)

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

> **⚠ Serialization rule**: Phases 12 and 13 share the Playwright MCP browser instance — see the same rule on Phase 12. Phase 13 MUST NOT be dispatched in the same assistant message as Phase 12, regardless of how the user answered the gate.

**Preconditions**: If `options.e2e_enabled = true`, Phase 12 MUST be present in `completed_phases` before Phase 13 starts. If it is not yet completed (e.g., E2E is still running or failed), do not start Phase 13 — return to the Phase 12 gate.

**Purpose**: Generate user-facing documentation with screenshots
**Execute**: `invoke_subagent` - `user-docs-generator` subagent
**Prompt must include**: task_path (absolute), spec_path, base_url. **When Phase 12 ran successfully** (E2E enabled and completed), also include `e2e_screenshots_path: {task_path}/verification/screenshots/` together with the instruction *"Reuse applicable E2E screenshots from this directory before capturing new ones via Playwright."* When Phase 12 was skipped or failed, omit `e2e_screenshots_path` entirely. Guide saves to `{task_path}/documentation/user-guide.md`.
**Output**: `documentation/user-guide.md`, screenshots (reused from E2E run when applicable)
**State**: Update docs generation status

**Skip if**: `options.user_docs_enabled = false`

→ **MANDATORY GATE** — fires regardless of permission mode, session-reminders, or prior approval patterns. Invoke `ask_question` now. Proceeding without a user response is a protocol violation (orchestrator-patterns.md § 2 / § 2.1).

ask_question - "Documentation complete. Continue to Phase 14?"

---

### Phase 14: Finalization

> **Phase entry self-check**: Before executing this phase, locate the `ask_question` tool call from the preceding phase in this conversation. If you cannot point to its call ID, STOP and fire that gate now. State updates (`completed_phases`, `update_steps`) without a corresponding `ask_question` call are protocol violations — never paper over a missed gate by updating state.

**Purpose**: Complete workflow and provide next steps
**Execute**: Direct - create summary, update state, guide commit
**Output**: Workflow summary
**State**: Set `task.status: completed`

**Preconditions** — read `orchestrator-state.yml` before finalizing. Every phase in the Phase Configuration table must be resolved:
- **Resolved** means the phase is in `completed_phases`, or its activation condition is false in state: Phase 3 (no reproducible defect), Phase 4 (`ui_heavy` false), Phase 6 (`spec_audit_enabled` false), Phase 9 (Phase 3 not run), Phase 12 (`e2e_enabled` false), Phase 13 (`user_docs_enabled` false). Phase 11 has no such condition — it must be completed.
- **Any unresolved phase blocks finalization.** Name it and use `ask_question` per phase: "Run Phase N now (Recommended)" returns to that phase; "Finalize without it" records the choice and the user's reason in `work-log.md`, the workflow summary, and the phase's dashboard `skip_reason`. Never finalize past an unresolved phase silently.

**Process**:
1. **Reconcile artifacts against disk** — compare every `artifacts[]` entry in state with what actually exists and name every missing path in the summary (`orchestrator-patterns.md` § 10)
2. Create workflow summary
3. Update task status to "completed"
4. Provide commit message template — following the repository's own commit-message rules (its agent instruction files or contributing guide). Those rules outrank generic tool defaults, such as default trailers.
5. Guide next steps (code review, PR, deployment)

→ End of workflow

---
