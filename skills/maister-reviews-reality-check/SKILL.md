---
name: maister-reviews-reality-check
description: >-
  Perform an evidence-based reality assessment on completed work to verify end-to-end functionality, error paths, and claimed vs actual completion.
---

# Reality Check (`/maister-reviews-reality-check`)

Delegates an independent end-to-end reality check to the `reality-assessor` subagent.

## Usage

```text
/maister-reviews-reality-check [task-path]
```

## Execution Steps

1. **Determine task path**:
   - Use the provided `.maister/tasks/...` directory (or code path). If omitted, list recent tasks under `.maister/tasks/` or ask via `ask_question`.
   - Report path: `[task-path]/verification/reality-check.md` (or `.maister/tasks/reviews/YYYY-MM-DD-reality-check/reality-check.md` if run outside a task folder).

2. **Delegate immediately via `invoke_subagent`**:
   ```text
   invoke_subagent:
     TypeName: "reality-assessor"
     Role: "Reality Assessor"
     Prompt: |
       Assess completion reality for task: [task-path]
       Write the report to: [report path]
   ```
   End your turn after launching `invoke_subagent` and wait for its completion message.

3. **Present summary**: Share claimed-vs-actual gaps, test execution evidence, pragmatic action plan, and the Ready / Issues Found / Not Ready verdict.
