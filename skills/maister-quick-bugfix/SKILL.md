---
name: maister-quick-bugfix
description: >-
  Lightweight TDD-driven bug fix with complexity escalation, plan approval, failing reproduction test (Red gate), fix + verification (Green gate), and Maister standards compliance.
---

# Quick Bug Fix (`/maister-quick-bugfix`)

Lightweight TDD-driven bug fix workflow: analyze root cause, get approval on a concise fix plan, reproduce with a failing test (Red gate), implement the fix with standards applied, and verify tests pass (Green gate). Escalates complex bugs to `/maister-development`.

## Usage

```text
/maister-quick-bugfix "Login form submits twice on slow connections"
/maister-quick-bugfix "API returns 500 when email contains special characters"
```

---

## Workflow

### Step 1: Parse Input

- Use the provided bug description argument, or extract symptoms/stack traces from recent conversation context.
- If neither exists, ask via `ask_question` or plain text: `"Describe the bug — what is the expected behavior vs actual behavior?"`

### Step 2: Discover Standards

- Read `.maister/docs/INDEX.md` (if present) and **read every specific standard file** matching the affected area (e.g., API/error-handling, validation/frontend, queries/models, testing). Reading `INDEX.md` alone is NOT sufficient.

### Step 3: Analyze Root Cause & Check Complexity

Investigate the codebase (read-only) until you have a root-cause hypothesis backed by file/line evidence, affected files, and existing test coverage.

**Complexity Escalation Check** — if **2 or more** signals apply, ask before continuing:
- Changes span 5+ files across multiple modules
- Requires database schema or data model migrations
- Multiple fix approaches with non-trivial architectural trade-offs
- Touches security-critical auth/crypto/permissions logic
- Root cause remains unclear after initial inspection

If triggered, call `ask_question`:
- Question: `"This bug appears more complex than a quick fix ([reason]). How would you like to proceed?"`
- Options: `["(Recommended) Switch to /maister-development workflow", "Continue with /maister-quick-bugfix anyway"]`
If switching, read and execute `../maister-development/SKILL.md` with the bug description and findings.

### Step 4: Present Fix Plan & Wait for Approval

Before editing any project files, present a concise fix plan (as an Antigravity plan artifact `implementation_plan.md` with `RequestFeedback: true` when an artifact directory is available, or inline followed by `ask_question` with `["(Recommended) Approve fix plan and start TDD Red gate", "Revise plan", "Cancel"]`).

**Mandatory plan sections** (do NOT proceed to Step 5 if any is missing):
1. `## Bug Analysis` — root cause hypothesis with file/line evidence + affected files
2. `## Proposed Fix` — what changes and why
3. `## Test Strategy` — what the failing reproduction test will assert
4. `## Applicable Standards` — matched standard files + key rules (or note to run `/maister-init` if absent)
5. `## Standards Compliance Checklist` — `- [ ]` checkboxes annotated with `(from standards/...)`

### Step 5: TDD Red Gate (Write Failing Test First)

1. Add a reproduction test in the appropriate test file asserting the expected (fixed) behavior.
2. Run the test via `run_command` and confirm **it FAILS** on current code.
3. If the test unexpectedly passes, stop and ask via `ask_question` whether reproduction conditions need adjustment.

### Step 6: Fix & Verify (TDD Green Gate)

1. Implement the approved fix adhering to the discovered standards.
2. Re-run the reproduction test (**must PASS**) plus related test suites to confirm zero regressions (max 3 fix iterations; if still failing after 3 attempts, stop and offer escalation to `/maister-development`).

### Step 7: Summary & Compliance Verification

Verify every item in the `## Standards Compliance Checklist` (fix any violation first), then report:
- Root cause & fix summary
- Modified files
- TDD Red → Green test output
- Completed Standards Compliance Checklist (pass/fail per item)
- Suggested commit message
