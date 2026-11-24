---
name: maister-quick-dev
description: >-
  Implement a clear, scoped task directly in the main agent with continuous Maister coding standards discovery and post-implementation compliance verification.
---

# Quick Dev — Direct Development with Standards Enforcement (`/maister-quick-dev`)

Implements a straightforward task directly in the main agent (no orchestrator directory, no subagent waves) while enforcing the project's coding standards from `.maister/docs/`.

## Usage

```text
/maister-quick-dev [task description]
```

## Workflow

1. **Get the task**:
   - Use the argument if provided, or extract from recent conversation context.
   - If neither is present, ask what the user wants to implement.

2. **Discover applicable standards**:
   - Read `.maister/docs/INDEX.md` to discover available project docs and coding standards.
   - **Read the specific matched standard files** under `.maister/docs/standards/` (and relevant `.maister/docs/project/` files) for every domain you touch. Reading `INDEX.md` alone is NOT sufficient.
   - Whenever implementation reaches a new area mid-task (e.g., auth, database queries, UI components, validation), check `INDEX.md` again and read its standards before writing that code.
   - If `.maister/docs/INDEX.md` does not exist, implement normally and note: `"No Maister standards found. Consider running /maister-init."`

3. **Implement the changes**:
   - Explore the relevant code, make clean changes adhering to the matched standards, and run relevant tests.

4. **Verify compliance (mandatory)**:
   - Before finishing, check every applicable guideline from the standards you read and include a **Standards Compliance Checklist** (pass/fail per guideline with its source file path) in your response alongside changed files and test results. Fix any compliance gap before completing.
