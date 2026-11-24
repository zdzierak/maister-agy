---
name: maister-reviews-production-readiness
description: >-
  Verify pre-deployment production readiness across configuration, monitoring, error handling, performance, security, and rollback safety.
---

# Production Readiness Review (`/maister-reviews-production-readiness`)

Delegates a 7-dimension pre-deployment audit to the `production-readiness-checker` subagent.

## Usage

```text
/maister-reviews-production-readiness [path] [--target=prod|staging]
```

## Execution Steps

1. **Determine target path and environment**:
   - **Path**: Use provided path (`.` for whole project, a directory, or a Maister task folder). If omitted, ask via `ask_question`.
   - **Target**: `production` (default, full rigor) or `staging` (`--target=staging`).
   - **Report path**: `[task-path]/verification/production-readiness-report.md` for a Maister task, or `.maister/tasks/reviews/YYYY-MM-DD-prod-readiness/production-readiness-report.md` otherwise.

2. **Delegate immediately via `invoke_subagent`**:
   ```text
   invoke_subagent:
     TypeName: "production-readiness-checker"
     Role: "Production Readiness Checker"
     Prompt: |
       Verify production readiness at: [path]
       Target: [production|staging]
       Report path: [report path]
   ```
   End your turn after launching `invoke_subagent` and wait for its completion message.

3. **Present summary**: Share the GO / DEPLOY WITH CAUTION / NO-GO verdict, deployment blockers, category scores, and link to the full report.
