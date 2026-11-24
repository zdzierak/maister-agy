---
name: maister-reviews-code
description: >-
  Run automated code quality, security, and performance analysis on a file, directory, or Maister task using the code-reviewer subagent.
---

# Code Review (`/maister-reviews-code`)

Delegates a comprehensive read-only code quality, security, and performance audit to the `code-reviewer` subagent.

## Usage

```text
/maister-reviews-code [path] [--scope=quality|security|performance|all]
```

## Execution Steps

1. **Determine target path and scope**:
   - **Path**: Use the path argument if provided. If omitted, check conversation context or ask via `ask_question` (e.g., current changes, a specific directory like `src/`, or a `.maister/tasks/...` folder).
   - **Scope**: `quality`, `security`, `performance`, or `all` (default: `all`).
   - **Report path**: If analyzing a Maister task folder, write to `[task-path]/verification/code-review-report.md`; otherwise write to `.maister/tasks/reviews/YYYY-MM-DD-code-review/code-review-report.md` (create directory first).

2. **Delegate immediately via `invoke_subagent`** (do not perform the review inline yourself):
   ```text
   invoke_subagent:
     TypeName: "code-reviewer"
     Role: "Code Quality & Security Reviewer"
     Prompt: |
       Analyze code at: [target path]
       Scope: [quality|security|performance|all]
       Report path: [report path]
   ```
   End your turn after launching `invoke_subagent` and wait for its completion message.

3. **Present summary**: Once `code-reviewer` finishes, summarize findings by severity (`Critical`, `Warning`, `Info`), link the generated report file, and highlight go/no-go recommendations.
