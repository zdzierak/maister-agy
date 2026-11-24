<div align="center">

# Maister for Google Antigravity

**Structured, standards-aware software development workflows for Google Antigravity (App, CLI `agy`, and IDE)**

Describe what you want to build, and Maister guides it from requirements and specification through planning and test-driven implementation to verification — enforcing your project's coding standards at every step.

</div>

> [!NOTE]
> **Fork & Attribution**: `maister-agy` ([zdzierak/maister-agy](https://github.com/zdzierak/maister-agy)) is a fork of **[SkillPanel/maister](https://github.com/SkillPanel/maister)**, originally created by Marek Kaluzny ([SkillPanel](https://skillpanel.com)) and contributors as a plugin for **Claude Code**. This repository adapts the full Maister SDLC framework — orchestrators, skills, subagents, rules, lifecycle hooks, and MCP integration — to run natively in **Google Antigravity** (`agy`).

## What You Get

- **Guided SDLC workflows** for features, bug fixes, enhancements, performance optimization, migrations, research, and interactive product design
- **Auto-discovered coding standards** from your codebase — config files, source patterns, project docs, and PR/CI conventions are analyzed, stored in `.maister/docs/standards/`, and continuously enforced
- **Test-driven implementation waves** with automated planning, parallel disjoint subagent execution (`invoke_subagent`), incremental test runs, and full-suite verification
- **Pause and resume** any workflow — full execution state is persisted in `orchestrator-state.yml` with a live browser operator dashboard (`dashboard.html`) and HTML companion reports
- **Production readiness & quality audits** including code review, specification auditing, reality assessment, and pragmatic over-engineering detection

## Getting Started

### Prerequisites

- **Google Antigravity** — Antigravity CLI (`agy`), Antigravity App, or Antigravity IDE
- **Node.js 20+** *(optional)* — required for the browser HTML visual companion in `/maister-mockup-studio` and the bundled `@playwright/mcp` server (without Node.js, UI mockups automatically fall back to terminal ASCII)

### Installation

#### Option 1: Install from GitHub via Antigravity CLI (`agy`)

```bash
agy plugin install https://github.com/zdzierak/maister-agy
```

#### Option 2: Install from a local clone

```bash
git clone git@github.com:zdzierak/maister-agy.git
agy plugin install ./maister-agy
```

Or inside an interactive `agy` TUI session:

```text
/plugin install /path/to/maister-agy
```

Verify installation and discovered components (`23 skills`, `25 agents`, `1 rule`, `2 hooks`, `1 MCP server`):

```bash
agy plugin list
```

> **Cross-surface sync**: Plugins installed via `agy plugin install` into `~/.gemini/config/plugins/maister` are available across both the **Antigravity CLI** and the **Antigravity App**. For workspace-only installation committed to version control, place or symlink the plugin folder at `.agents/plugins/maister/`.

### Initial Project Setup

Initialize your project to analyze the codebase, generate baseline project docs, and auto-discover coding standards:

```text
/maister-init
```

This creates `.maister/` (with `config.yml`, `docs/INDEX.md`, `docs/project/`, `docs/standards/`, and `tasks/`) and integrates `.maister/docs/INDEX.md` into your workspace `AGENTS.md` (or `GEMINI.md`).

To reuse standards from another project already using Maister:

```text
/maister-init --standards-from=/path/to/other-project
```

### Starting Your First Workflow

Run a workflow directly with a description:

```text
/maister-development Add user profile page with avatar upload
```

Or use the unified entry point to auto-classify any task, bug, or GitHub/Jira issue:

```text
/maister-work "Fix 500 error on login when session cookie expires"
```

Every workflow command also works **without arguments** — it extracts the task description from your active conversation context:

```text
You: The dashboard takes 6 seconds to render when a team has >500 items
You: /maister-performance
```

## Supported Workflows & Commands

### Workflow Orchestrators

| Command | Use When |
|---------|----------|
| `/maister-work` | Unified entry point — classifies a new task or resumes an existing `.maister/tasks/` folder |
| `/maister-development` | Features, bug fixes, enhancements, refactoring (14 adaptive phases, TDD Red/Green gates, UI mockups) |
| `/maister-research` | Multi-source research with synthesis, solution brainstorming, C4 diagrams, and MADR decisions |
| `/maister-performance` | Static bottleneck detection (N+1, missing indexes, O(n²), blocking I/O, memory leaks) + optimization |
| `/maister-migration` | Framework, database, or architecture migrations with mandatory rollback and dual-run plans |
| `/maister-product-design` | Interactive product/feature design from problem exploration to layered brief and visual prototypes |
| `/maister-mockup-studio` | Standalone HTML/CSS browser visual companion (or ASCII fallback) bound to your real design tokens |

### Quick Commands (No Task Directory)

| Command | Use When |
|---------|----------|
| `/maister-quick-plan` | Draft a reviewable plan with a mandatory Standards Compliance Checklist before coding |
| `/maister-quick-dev` | Implement a clear, scoped change directly with continuous standards enforcement |
| `/maister-quick-bugfix` | Lightweight TDD bug fix (plan → failing test → fix → green test) with complexity escalation |

### Standards & Standalone Reviews

| Command | Use When |
|---------|----------|
| `/maister-init` | Initialize `.maister/`, project docs, `AGENTS.md` / `GEMINI.md` integration, and standards discovery |
| `/maister-standards-discover` | Scan config files, code patterns, docs, PRs, and CI/CD in parallel for coding conventions |
| `/maister-standards-update` | Add/refine standards from conversation context, description, or `--from=PATH` project sync |
| `/maister-reviews-code` | Automated code quality, security, and performance review (`--scope=quality\|security\|performance\|all`) |
| `/maister-reviews-pragmatic` | Detect over-engineering and unnecessary complexity relative to project scale |
| `/maister-reviews-spec-audit` | Independent pre- or `--post-implementation` specification audit |
| `/maister-reviews-reality-check` | End-to-end reality check comparing claimed vs actual completion |
| `/maister-reviews-production-readiness` | 7-dimension GO/NO-GO pre-deployment verification (`--target=prod\|staging`) |

## Best Practices in Google Antigravity

- **Use `auto` or `accept-edits` mode, not `/plan` mode, for full orchestrators.** Orchestrator workflows write state (`orchestrator-state.yml`), specs, plans, and dashboards under `.maister/tasks/` as they progress, and pause for your input at every `→ MANDATORY GATE` via Antigravity's native `ask_question` UI. Running inside read-only `/plan` mode blocks artifact creation.
- **Monitor parallel subagents live.** During codebase analysis, research gathering, implementation waves, and verification, Maister launches concurrent background subagents via `invoke_subagent`. Inspect them anytime in the **Subagents** side panel (App) or `/agents` (`Alt+J` / `Ctrl+K` for fast approvals in CLI).
- **Start chained workflows in a fresh session (`/clear` / New Conversation).** Pass a completed research or product-design directory directly to `/maister-development`:
  ```text
  /maister-development .maister/tasks/research/2026-11-24-oauth-research
  /maister-development .maister/tasks/product-design/2026-11-24-dashboard-redesign
  ```
- **Resume anytime.** If a session is closed or compacted, resume from disk state by passing the task folder:
  ```text
  /maister-development .maister/tasks/development/2026-11-24-my-feature
  ```

## How This Fork Adapts Claude Code Maister to Antigravity

| Area | Original (`SkillPanel/maister` for Claude Code) | `maister-agy` (Google Antigravity) |
|------|-------------------------------------------------|------------------------------------|
| **Manifest** | `.claude-plugin/plugin.json` + `marketplace.json` | Root `plugin.json` (`antigravity.google/schemas/v1/plugin.json`) |
| **Slash commands** | `/maister:*` across `commands/` + `skills/` | Unified `/maister-*` skills in `skills/<name>/SKILL.md` |
| **Large orchestrators** | Monolithic `SKILL.md` up to 55 KB | Progressive disclosure: `SKILL.md` (<24 KB) + `references/workflow-phases.md` |
| **Subagent delegation** | Synchronous `Task` tool (`subagent_type`, `Explore`) | Async `invoke_subagent` (`TypeName`, built-in `research` & `self`) |
| **Skill delegation** | `Skill` tool | Main-context `read_file` execution of sibling `SKILL.md` |
| **Interactive gates** | `AskUserQuestion` | Native `ask_question` (single- & multi-select + `(Recommended)`) |
| **Live progress** | `TaskCreate` / `TaskUpdate` (`addBlockedBy`) | Native `update_steps` live checklist + `orchestrator-state.yml` |
| **Workspace rules** | `CLAUDE.md` | Always-on plugin `rules/AGENTS.md` + project `AGENTS.md` / `GEMINI.md` |
| **Lifecycle hooks** | `hooks/hooks.json` (`Bash`, `CLAUDE_PLUGIN_ROOT`) | Root `hooks.json` + `./scripts/*.sh` (`run_command`, camelCase JSON) |
| **MCP configuration** | `.mcp.json` | `mcp_config.json` (`@playwright/mcp@0.0.83`) |

## Validation & Development

```bash
# Run strict Antigravity plugin validation + repository consistency checks
make validate
```

## Learn More

- [Workflow Details](docs/workflows.md) — phases, state structure, and handoffs for every workflow
- [Full Command Reference](docs/commands.md) — flags, examples, and options for all 18 `/maister-*` commands
- [Plugin Architecture & Contributor Guide](docs/architecture.md) — internal skills, subagents, hooks, and authoring rules
- Upstream project: [SkillPanel/maister](https://github.com/SkillPanel/maister)

## License

MIT — see [LICENSE](LICENSE). Original work Copyright (c) 2025-2026 Marek Kaluzny (SkillPanel.com) and Maister contributors.
