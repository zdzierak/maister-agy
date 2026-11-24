---
name: maister-reviews-pragmatic
description: >-
  Run a pragmatic code review to detect over-engineering, premature abstraction, and unnecessary complexity relative to project scale.
---

# Pragmatic Code Review (`/maister-reviews-pragmatic`)

Delegates pragmatic simplicity and scale-fit analysis to the `code-quality-pragmatist` subagent.

## Usage

```text
/maister-reviews-pragmatic [path]
```

## Execution Steps

1. **Determine target path**:
   - Use the provided file, directory, or `.maister/tasks/...` path. If omitted, ask via `ask_question`.
   - Choose report output path: `[task-path]/verification/pragmatic-review.md` if reviewing a Maister task, or `.maister/tasks/reviews/YYYY-MM-DD-pragmatic-review/pragmatic-review.md` otherwise.

2. **Delegate immediately via `invoke_subagent`**:
   ```text
   invoke_subagent:
     TypeName: "code-quality-pragmatist"
     Role: "Pragmatic Code Reviewer"
     Prompt: |
       Review the code at: [path]
       Project scale docs: .maister/docs/project/ (if present)
       Spec (if any): [spec path if reviewing a task]
       Write the report to: [report path]
   ```
   End your turn after launching `invoke_subagent` and wait for its completion message.

3. **Present summary**: Report complexity assessment, top simplification opportunities with before/after impact, and link the saved report.
