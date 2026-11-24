# Maister Architecture & Contributor Guide (Google Antigravity)

> **Upstream Origin**: `maister-agy` ([zdzierak/maister-agy](https://github.com/zdzierak/maister-agy)) is a native Google Antigravity fork of **[SkillPanel/maister](https://github.com/SkillPanel/maister)**, which was originally created for **Claude Code**.

## Repository Layout

This repository is a standalone native Google Antigravity plugin (`plugin.json` at the repository root) so `agy plugin install` and `agy plugin validate --strict` work directly against the repository root:

```text
maister-agy/
├── plugin.json               # Antigravity plugin manifest (https://antigravity.google/schemas/v1/plugin.json)
├── mcp_config.json           # Bundled MCP servers (@playwright/mcp@0.0.83)
├── hooks.json                # Lifecycle hooks (SessionStart, PreToolUse on run_command)
├── scripts/                  # Executable (0755) hook scripts invoked relative to plugin root
│   ├── session-start-reminder.sh
│   └── block-destructive-commands.sh
├── assets/
│   └── logo.svg              # 128x128 1:1 square plugin icon
├── rules/
│   └── AGENTS.md             # Always-on plugin rule (<24 KB) injected when plugin is enabled
├── agents/                   # 25 custom subagent definitions (*.md, subagent: true, mainAgent: false)
├── skills/                   # 23 skills (18 /maister-* slash commands + 5 internal skills)
├── docs/                     # User & contributor documentation
│   ├── commands.md
│   ├── workflows.md
│   └── architecture.md
├── Makefile                  # Strict validation (`make validate`)
└── README.md                 # Marketplace & GitHub documentation
```

> **Important**: Do **not** place a standalone `AGENTS.md`, `GEMINI.md`, `CLAUDE.md`, `.mcp.json`, or `commands/` directory at the repository root — Antigravity's strict plugin validator (`agy plugin validate --strict`) flags root files meant for other tools as ignored/shadowed warnings. Always place active plugin rules inside `rules/` and contributor documentation inside `docs/`.

---

## Key Antigravity Authoring Rules

### 1. Progressive Disclosure & the 24 KB `SKILL.md` Cap

Antigravity loads only the **first `24,000` bytes** of any `SKILL.md` body (and `24,000` bytes per rule file in `rules/`). `agy plugin validate --strict` treats bodies over 24,000 bytes as warnings/errors.

- Every `skills/<name>/SKILL.md` **must** stay under `24,000` bytes.
- Large orchestrators (`maister-development`, `maister-product-design`, `maister-research`, `maister-migration`, `maister-performance`) keep initialization, cross-cutting operator visibility rules, and phase tables in `SKILL.md`, and place unabridged phase logic in `references/workflow-phases.md` (`< 45,000` bytes so a single `read_file` call loads the entire file without truncation).
- Frontmatter in `SKILL.md` uses only Antigravity-supported fields (`name` matching parent folder in lowercase `kebab-case`, `description`, optional `disable-model-invocation`, `license`, `compatibility`).

### 2. Custom Subagents (`agents/*.md`)

- Frontmatter fields: `name`, `description`, `model` (`inherit`, `flash_lite`, `flash`, or `pro`), `subagent: true`, `mainAgent: false`, and optional `skills: ["skills/<skill-name>"]` (used by `docs-operator`).
- Omit the `tools` allowlist unless strictly needed with verified surface-identical tool names, because tool identifiers differ across Antigravity surfaces and unmapped names can stall subagent startup; safety guards are enforced via prompts and `hooks.json` (`PreToolUse` on `run_command`).

### 3. Delegation & Asynchronous Execution

- **Internal skills**: Antigravity has no `Skill` tool. Orchestrators execute internal skills (`codebase-analyzer`, `maister-mockup-studio`, `implementation-plan-executor`, `implementation-verifier`) by reading `../<skill-name>/SKILL.md` via `read_file` in the main agent context and following its steps.
- **Subagents**: Spawned via `invoke_subagent(TypeName="<agent>", Role="...", Prompt="...")`. Built-in exploration uses `TypeName: "research"`; general file-writing tasks without a dedicated template use `TypeName: "self"`.
- **Reactive wakeup**: `invoke_subagent` runs asynchronously. Emit all `invoke_subagent` calls for a single subagent or parallel wave in **one turn**, then end the turn without polling — Antigravity automatically wakes the main agent when completion messages arrive.

### 4. Phase Gates (`ask_question`) & Progress (`update_steps`)

- Every `→ MANDATORY GATE` calls `ask_question` (`questions: [{question, options, is_multi_select}]`, with `(Recommended)` on the first option when recommended). Antigravity's UI automatically adds numbering and an `Other` free-text input.
- Orchestrators mirror high-level progress in the UI with `update_steps` (up to 12 items, always sending the full ordered list with `pending` / `in_progress` / `done` / `skipped` / `failed`), while `orchestrator-state.yml` and `implementation-plan.md` checkboxes remain the persistent source of truth on disk.

### 5. Lifecycle Hooks (`hooks.json` & `scripts/`)

- `hooks.json` lives at the plugin root and groups handlers under named hook keys (`maister-session-state`, `maister-destructive-guard`).
- Helper scripts live in `scripts/` with `0755` permissions so Marketplace bundles preserve executability.
- Hook payloads on `stdin` use camelCase (`cwd`, `toolCall.args.CommandLine`) and scripts output valid JSON on `stdout` (`{}` for pass-through, `{"injectSteps": [...]}` in `SessionStart`, `{"decision": "force_ask", "reason": "..."}` in `PreToolUse`) with exit code `0`.

---

## Validating Changes

Always run `make validate` before committing:

```bash
make validate
```

This executes `agy plugin validate --strict .` alongside repository checks verifying skill sizes, hook script paths, executable permissions, and absence of legacy Claude-only identifiers.
