---
name: orchestrator-framework
description: >-
  Internal Maister workflow skill (invoked as shared reference by Maister orchestrators, not directly by users). Shared orchestration patterns for phase execution, state management, ask_question gates, invoke_subagent delegation, update_steps tracking, and initialization.
---

# Orchestrator Framework

This skill provides **shared reference documentation** for all orchestrator skills in the Maister plugin for Google Antigravity. It is NOT an executable workflow on its own — orchestrators read its reference files and apply them to their domain.

## Purpose

Reduce duplication across orchestrators by documenting common patterns once:

- **Phase Blocks**: Clean phase structure with explicit transitions (`→ MANDATORY GATE`, `→ AUTO-CONTINUE`) — see `references/orchestrator-patterns.md` § 2
- **Delegation in Antigravity**: Reading/executing sibling `SKILL.md` files in the main agent context vs asynchronous `invoke_subagent` execution — see `references/orchestrator-patterns.md` § 1
- **State Management**: `orchestrator-state.yml` schema, UTC clock timestamps, and in-place YAML write rules — see `references/orchestrator-patterns.md` § 4
- **Progress Visibility**: `update_steps` live UI checklist + `dashboard.html` / `dashboard-data.js` operator dashboard

## How Orchestrators Use This

Each orchestrator reads the framework reference file at initialization (Step 1):

```markdown
### Step 1: Load Framework Patterns

**Read the framework reference file NOW using `read_file`:**

1. `../orchestrator-framework/references/orchestrator-patterns.md`
```

## Reference Files

| File | Purpose |
|------|---------|
| `references/orchestrator-patterns.md` | Delegation rules, `invoke_subagent` async execution, `ask_question` phase gates, state schema, `update_steps` initialization, context passing, issue resolution |
| `references/orchestrator-creation-checklist.md` | Authoring checklist for creating new orchestrators (not loaded at runtime) |
| `references/html-report-style.md` | Style guide for HTML companion reports (passed to companion-writing agents) |
| `assets/dashboard.html` | Static operator dashboard copied into every task directory |

## Key Principles

1. **State-Driven Execution**: `orchestrator-state.yml` is the persistent source of truth on disk
2. **Resume Capability**: Any orchestrator can be paused and resumed from its task folder
3. **Interactive Gates**: Pause via `ask_question` at every `→ MANDATORY GATE` for user review
4. **User-Confirmed Rollback**: Never auto-rollback without explicit user approval
5. **Live Checklist**: Track active workflow phases with `update_steps` (up to 12 steps)
6. **Standards Discovery**: Reference `.maister/docs/INDEX.md` throughout

## Orchestrators Using This Framework

- `maister-development` (bug fixes, enhancements, features)
- `maister-performance`
- `maister-migration`
- `maister-research`
- `maister-product-design`

Library consumers (read and write the same state and artifacts):

- `implementation-plan-executor`
- `implementation-verifier`
