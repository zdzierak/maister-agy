# AGENTS.md / GEMINI.md Documentation Section Template

Add this section to the project's `AGENTS.md` file (or `GEMINI.md` if the project already uses `GEMINI.md` for Antigravity workspace rules; prefer updating whichever exists, or create `AGENTS.md` at the repository root if neither exists). Place it prominently near the top. Verify `.maister/docs/INDEX.md` exists before adding.

```markdown
## Project Documentation & Standards

Before writing or changing any code — even for quick, direct requests that don't go through a `/maister-*` workflow — ground yourself in the project's documentation:

1. Read `.maister/docs/INDEX.md` (`@[.maister/docs/INDEX.md](.maister/docs/INDEX.md)`) to see what is documented. It is the map to everything the team maintains — coding standards by domain, project vision/tech-stack/architecture, and domain knowledge.
2. Then open and read the specific files it points to that are relevant to your task — standards AND any project/domain docs. Reading the index alone is not enough.
3. Follow the standards as you work (they represent team decisions; if one conflicts with the task, ask the user) and use the project docs as context.

### Standards Evolution

When you notice recurring patterns, fixes, or conventions during implementation that aren't yet captured in standards — suggest adding them:
- A bug fix reveals a pattern that should be standardized (e.g., "always validate X before Y")
- Code review feedback identifies a convention the team wants enforced
- The same type of fix is needed across multiple files
- A new library or architectural pattern is adopted that should be documented

Briefly suggest the standard to the user. If approved, run `/maister-standards-update` with the identified pattern.

## Maister Workflows

This project uses Maister for Google Antigravity (`/maister-*` skills). When any `/maister-*` command is invoked, read and execute its `SKILL.md` immediately — do not skip workflows for "straightforward" tasks. Complexity assessment is the workflow's job.
```
