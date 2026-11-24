# maister-development — Domain Context, Task Structure & Handoffs

## Domain Context (State Extensions)

Development-specific fields in `orchestrator-state.yml`:

```yaml
orchestrator:
  options:
    html_output: true  # Seeded from .maister/config.yml at init (default true). Gates dashboard + HTML companions.
    mockup_format: html  # Seeded from .maister/config.yml at init (default html). Passed to mockup-studio in Phase 4. Auto-falls back to ascii when Node unavailable.
    spec_audit_enabled: true
    skip_test_suite: true
    e2e_enabled: null
    user_docs_enabled: null
    code_review_enabled: true
    pragmatic_review_enabled: true
    reality_check_enabled: true
    production_check_enabled: true
  task_context:
    risk_level: null
    clarifications_resolved: null
    scope_expanded: null
    architecture_decision: null
    task_characteristics:
      has_reproducible_defect: false
      modifies_existing_code: false
      creates_new_entities: false
      involves_data_operations: false
      ui_heavy: false
    research_reference:
      path: null
      research_question: null
      research_type: null
      confidence_level: null
    design_reference:
      source: null  # "product-design" | "inline-prompt" | "legacy-migration" | null
      product_design_path: null  # set when Source 1 detected
      mockup_count: 0
      has_brief: false
      index_path: null  # path to analysis/design-context/INDEX.md
    phase_summaries:
      # Every entry also carries the shared base shape (orchestrator-patterns.md § 4):
      #   decisions: []   risks: []   artifacts: [{path, label, html}]
      research: {summary: null, key_findings: [], recommended_approach: null}
      design: {summary: null, screen_count: 0, component_count: 0, index_path: null}
      codebase_analysis: {key_files: [], primary_language: null, summary: null}
      clarifications: []
      gap_analysis: {integration_points: [], summary: null}
      scope_clarifications: {scope_expanded: null, summary: null}
      ui_mockups: {components_designed: [], summary: null}
      specification: {summary: null}
      architecture_decision: {decision: null, summary: null}
```

---

## Task Structure

```
.maister/tasks/development/YYYY-MM-DD-task-name/
├── orchestrator-state.yml
├── dashboard.html                 # Operator dashboard (copied plugin asset — never model-generated)
├── dashboard-data.js              # Dashboard data projection (rewritten after each phase/gate)
├── analysis/
│   ├── research-context/          # If --research provided
│   ├── design-context/            # If mockups detected (Step 4 ingestion or Phase 4 generation)
│   │   ├── mockups/               # HTML mockups (Phase 4 mockup-studio html path, product-design, or inline prompt) + PNG/screenshots
│   │   ├── ascii/                 # ASCII mockups (Phase 4 mockup-studio ascii path)
│   │   ├── design-resources.md    # Discovered design language (standards/tokens/components) — from mockup-studio
│   │   ├── brief.md               # Product brief (when ingested from product-design task)
│   │   ├── external-links.md      # Figma/Sketch/Zeplin URLs (no fetch — for reference)
│   │   └── INDEX.md               # Screen/component inventory with stable IDs
│   ├── codebase-analysis.md       # Phase 1
│   ├── clarifications.md          # Phase 1
│   ├── gap-analysis.md            # Phase 2
│   ├── scope-clarifications.md    # Phase 2 (conditional)
│   └── technical-clarifications.md # Phase 5 (conditional)
├── implementation/
│   ├── spec.md                    # Phase 5
│   ├── spec.html                  # Phase 5 (HTML companion)
│   ├── requirements.md            # Phase 5
│   ├── implementation-plan.md     # Phase 7
│   ├── implementation-plan.html   # Phase 7 (HTML companion)
│   ├── visual-coverage.md         # Phase 7 (when design-context exists)
│   ├── work-log.md                # Phase 8
│   ├── tdd-red-gate.md            # Phase 3 (conditional)
│   └── tdd-green-gate.md          # Phase 9 (conditional)
├── verification/
│   ├── spec-audit.md              # Phase 6 (recommended)
│   ├── implementation-verification.md  # Phase 11
│   ├── implementation-verification.html # Phase 11 (HTML companion)
│   ├── e2e-verification-report.md      # Phase 12 (optional)
│   ├── e2e-verification-report.html    # Phase 12 (HTML companion)
│   ├── visual-fidelity.md              # Phase 12 (when design-context exists, report-only)
│   └── visual-fidelity.html            # Phase 12 (HTML companion)
└── documentation/
    └── user-guide.md              # Phase 13 (optional)
```

---

## Auto-Recovery

| Phase | Max Attempts | Strategy |
|-------|--------------|----------|
| 1 | 2 | Expand search, prompt user |
| 2 | 2 | Re-analyze, ask user |
| 3 | 2 | Rewrite test, skip TDD with doc |
| 5 | 2 | Regenerate spec |
| 7 | 2 | Regenerate plan |
| 8 | 5 | Fix syntax, imports, tests |
| 9 | 3 | Return to implementation |
| 11 | 3 | Fix tests, re-run |

---

## Command Flags

| Flag | Effect |
|------|--------|
| `--from=PHASE` | Start from specific phase |
| `--research=PATH` | Link to completed research task |
| `--audit` / `--no-audit` | Force/skip specification audit |
| `--e2e` / `--no-e2e` | Force/skip E2E testing |
| `--user-docs` / `--no-user-docs` | Force/skip user documentation |
| `--sequential` | Disable parallel wave dispatch in the executor; run one task group at a time. Persisted as `orchestrator.options.sequential: true` in `orchestrator-state.yml` and read by `implementation-plan-executor` Phase 2. Defaults to off (parallel waves). |

---

## Research-Based Development

When starting development from a completed research task, the orchestrator loads research context to **INFORM** all phases.

### Invocation Methods

**Method 1: Research folder as sole argument** (recommended)
```
/maister-development .maister/tasks/research/2026-01-12-oauth-research
```
The orchestrator auto-detects this is a research folder and:
- Extracts task description from `research_context.research_question`
- Reads all research artifacts
- Sets `research_reference` in state

**Method 2: Explicit --research flag**
```
/maister-development "Implement OAuth" --research=.maister/tasks/research/2026-01-12-oauth-research
```

### Research Artifacts (Standard List)

When research context is detected, read these files from the research folder:

| Artifact | Path | Purpose |
|----------|------|---------|
| State | `orchestrator-state.yml` | research_type, confidence_level |
| Report | `outputs/research-report.md` | Main findings and conclusions |
| Solution Exploration | `outputs/solution-exploration.md` | Alternatives and trade-offs (input to Phase 5) |
| High-Level Design | `outputs/high-level-design.md` | C4 architecture (input to Phase 5) |
| Decision Log | `outputs/decision-log.md` | ADR decisions (input to Phase 5) |

### How Research Informs Each Phase

**Research INFORMS phases, never SKIPS them.** Research context passes to ALL phases via `task_context.phase_summaries.research`. No phases are skipped.

| Phase | How Research Context is Used |
|-------|------------------------------|
| Phase 1 | Codebase analyzer receives research findings as search guidance |
| Phase 2 | Gap analyzer uses research recommendations for comparison |
| Phase 5 | Specification creator uses high-level-design.md as INPUT (still creates full spec). Architecture decisions use research report AND decision-log.md (lighter when ADRs comprehensive) |
| Phase 7 | Implementation planner references research approach for task grouping |

---

## Design-Informed Development

When mockups or design artifacts are present, they become **binding inputs** to implementation — not optional references. The `analysis/design-context/` directory unifies all visual sources (product-design output, inline prompt references, Phase 4 ASCII generation) and propagates through every downstream phase.

### Auto-Detection Sources (Step 4 of Initialization)

**Source 1 — Product-design task path** (recommended handoff):
```
/maister-development .maister/tasks/product-design/2026-05-09-user-dashboard/
```
Auto-detected when the argument resolves to a `.maister/tasks/product-design/*` directory. Brief and mockups are copied into `design-context/`.

**Source 2 — Inline mockup paths in task description**:
```
/maister-development "Implement the dashboard from /tmp/dashboard-mockup.html"
```
Auto-detected file paths (`.html`, `.png`, `.jpg`, `.jpeg`, `.gif`, `.svg`, `.pdf`) are copied into `design-context/mockups/`. Design-tool URLs (Figma, Sketch Cloud, Zeplin) are recorded in `design-context/external-links.md`.

**Source 3 — Phase 4 generation via `mockup-studio`**: When no external mockups exist and `task_characteristics.ui_heavy` is true, Phase 4 invokes `mockup-studio` (skill `SKILL.md` execution). It produces HTML mockups in `design-context/mockups/` by default, or ASCII in `design-context/ascii/` when `mockup_format: ascii` (or Node is unavailable).

### How Design Context Informs Each Phase

**Design INFORMS phases, never SKIPS them.** Design context passes via `task_context.phase_summaries.design` and `task_context.design_reference`.

| Phase | How Design Context is Used |
|-------|------------------------------|
| Phase 4 | Skipped if `design-context/mockups/` already populated; otherwise invokes `mockup-studio` → HTML in `design-context/mockups/` (default) or ASCII in `design-context/ascii/` |
| Phase 5 | `specification-creator` reads from `design-context/` (single source); produces "Visual Design" section in spec.md |
| Phase 7 | `implementation-planner` enumerates screens from `design-context/INDEX.md`, attaches required `Visual References` to UI task groups, produces `implementation/visual-coverage.md` proving every screen is covered by ≥1 group |
| Phase 8 | `task-group-implementer` reads each referenced mockup before coding; layout, copy, field order, and explicit states are binding |
| Phase 12 | `e2e-test-verifier` performs LLM-judged structural visual-fidelity comparison after capturing screenshots; writes `verification/visual-fidelity.md` (report-only, never gates completion) |

### Graceful Degradation

When no mockups are detected at any source, the entire design-context machinery is skipped:
- No `design-context/` directory
- No `design_reference` in state (remains null)
- No `Visual References` field in task groups (planner omits the section entirely)
- No `visual-coverage.md` or `visual-fidelity.md`

Non-UI tasks see zero behavior change.

---

## Command Integration

Invoked via:
- `/maister-development [description] [--e2e] [--user-docs] [--research=PATH]` (new)
- `/maister-development [task-path] [--from=PHASE] [--reset-attempts]` (resume)

---

## TDD Gate Rules

**Phase 3 (Red Gate)**: Test MUST FAIL before implementation (activated when gap-analyzer detects reproducible defect)
**Phase 9 (Green Gate)**: Test MUST PASS after implementation (activated when Phase 3 was executed)
