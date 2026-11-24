---
name: maister-quick-plan
description: >-
  Draft a reviewable implementation plan with Maister coding standards discovery and a mandatory Standards Compliance Checklist before writing code.
---

# Quick Plan — Planning with Standards Enforcement (`/maister-quick-plan`)

Creates a reviewable implementation plan grounded in `.maister/docs/` coding standards, pauses for user approval, and verifies standards compliance after implementation — without spinning up a full `.maister/tasks/` orchestrator directory.

## Usage

```text
/maister-quick-plan [task description]
```

## Workflow

1. **Get the task**:
   - Use the argument if provided, or extract from recent conversation context.
   - If neither is present, ask via `ask_question` or plain text: `"What would you like to plan?"`

2. **Explore & discover standards (read-only — do NOT edit project files yet)**:
   - Explore the relevant codebase files to design a concrete implementation approach.
   - Read `.maister/docs/INDEX.md` to identify documented project standards and architecture docs.
   - **Read every matched standard file** referenced by `INDEX.md` that applies to the files/domains involved. Reading `INDEX.md` alone is NOT sufficient.
   - If `.maister/docs/INDEX.md` does not exist, note in the plan: `"No Maister standards found. Consider running /maister-init."`

3. **Draft the plan and pause for user approval**:
   - Include:
     1. **Goal & Affected Files**
     2. **Proposed Implementation Steps** (referencing governing standards where they shape decisions)
     3. **Verification / Test Plan**
     4. **`## Standards Compliance Checklist`** — one `- [ ]` checkbox per applicable guideline annotated with its source file, e.g. `(from standards/backend/api.md)`
   - When an Antigravity artifact directory (`<appDataDir>/brain/<conversation-id>/`) is available, write the plan to `implementation_plan.md` in the artifact directory with `ArtifactMetadata: {Summary: "...", UserFacing: true, RequestFeedback: true}` so the user gets Antigravity's native plan review UI. Otherwise, present the plan inline and confirm via `ask_question` (`["(Recommended) Approve plan and implement", "Revise plan", "Cancel"]`).
   - **Wait for explicit user approval before modifying any project files.**

4. **Implement & verify compliance (mandatory after approval)**:
   - Implement the approved plan while honoring any mid-task standards discovered from `INDEX.md`.
   - Walk through every item in the **`## Standards Compliance Checklist`**, verify pass/fail, resolve any compliance failure before finishing, and include the completed checklist in your final summary.
