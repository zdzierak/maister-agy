---
name: maister-reviews-spec-audit
description: >-
  Run an independent senior-auditor specification review to detect ambiguities, contradictions, and gaps (pre-implementation or post-implementation).
---

# Specification Audit (`/maister-reviews-spec-audit`)

Delegates an independent specification audit to the `spec-auditor` subagent.

## Usage

```text
/maister-reviews-spec-audit [spec-path | task-path] [--post-implementation]
```

## Execution Steps

1. **Determine specification path and audit mode**:
   - **Path**: Use the provided `spec.md` or Maister task directory path. If omitted, ask via `ask_question`.
   - **Mode**: `post-implementation` when `--post-implementation` is passed or implementation already exists alongside the spec; otherwise `pre-implementation`.
   - **Report path**: `[task-dir]/verification/spec-audit.md` (or `.maister/tasks/reviews/YYYY-MM-DD-spec-audit/spec-audit.md`).

2. **Delegate immediately via `invoke_subagent`**:
   ```text
   invoke_subagent:
     TypeName: "spec-auditor"
     Role: "Specification Auditor"
     Prompt: |
       Audit the specification at: [spec-path]
       Mode: [pre-implementation|post-implementation]
       Write the report to: [report-path]
       List open ambiguities as questions in the report.
   ```
   End your turn after launching `invoke_subagent` and wait for its completion message.

3. **Present summary**: Share compliance status (`Compliant` / `Mostly Compliant` / `Non-Compliant`), critical/high findings with evidence, and open stakeholder questions.
