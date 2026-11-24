---
name: codebase-analyzer
description: >-
  Internal Maister workflow skill (invoked by Maister orchestrators, not directly by users). Analyzes the codebase using adaptive parallel research subagents based on task complexity, then delegates report synthesis to the codebase-analysis-reporter subagent.
---

# Codebase Analyzer Skill

Orchestrates parallel codebase exploration using Antigravity's built-in `research` subagent, adaptively selecting analysis roles based on task complexity and delegating final report synthesis to `codebase-analysis-reporter`.

## Core Principles

1. **Adaptive Role Selection**: Select roles from a pool based on task complexity — no fixed count.
2. **Task-Type Awareness**: Tailor prompts and focus areas to bug fixes, enhancements, features, performance, or migrations.
3. **Delegated Reporting**: Raw findings from parallel `research` subagents go to `codebase-analysis-reporter` (`invoke_subagent`) to write the structured markdown report on disk.

---

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `task_description` / `description` | Yes | Description of the task from the user/orchestrator |
| `task_path` | Yes | Path to the active `.maister/tasks/...` directory |
| `artifact_name` | No | Output filename under `analysis/` (default: `codebase-analysis.md`) |

---

## Execution Workflow

### Step 1: Parse Input and Determine Primary Focus

| Signal in Description | Primary Focus | Key Questions |
|----------------------|---------------|---------------|
| Error/crash/broken language | Find buggy code path | Where does the issue occur? What is the execution flow? |
| Improve/enhance/existing | Find existing feature | What files implement this feature? How does it work? |
| Add/new/create | Find patterns/integration points | What similar patterns exist? Where should this integrate? |

### Step 2: Select Agent Roles

| Role | Purpose | When Needed |
|------|---------|-------------|
| **File Discovery** | Find relevant files by patterns, keywords, naming | Almost always |
| **Code Analysis** | Analyze code structure, patterns, execution flow | When understanding existing behavior matters |
| **Context Discovery** | Find tests, consumers, dependencies | When understanding impact/coverage matters |
| **Pattern Mining** | Find similar implementations as templates | New features following existing patterns |
| **Migration Target** | Analyze target technology/compatibility | Migrations comparing current vs target |

State which roles you selected and why (1 sentence). When selecting fewer agents, merge related concerns into one prompt rather than dropping concerns.

### Step 3: Read Prompt Templates and Launch Parallel `research` Subagents

1. **Read templates** using `read_file` (relative to this `SKILL.md` directory) ONLY for your selected roles:
   - File Discovery → `references/file-discovery.md`
   - Code Analysis → `references/code-analysis.md`
   - Context Discovery → `references/context-discovery.md`
   - Pattern Mining → `references/pattern-mining.md`
   - Migration Target → `references/migration-target.md`
   - Merging multiple roles into 1 agent → `references/combined.md`

2. **Adapt templates** — Replace `[description]` with the actual task description and select the appropriate task-type section. Always keep the read-only instruction:
   > IMPORTANT: Do NOT create, write, or modify any files. Output all findings as text in your response only.

3. **Launch all selected `research` subagents in parallel in ONE turn**:
   Emit one `invoke_subagent` call per selected role (`TypeName: "research"`, `Role: "<Role Name>"`, `Prompt: "..."`) in the same turn, then **end your turn** (do not poll) so Antigravity wakes you as they complete. Wait until ALL launched `research` subagents have returned their findings before starting Step 4.

### Step 4: Delegate Report Generation (`codebase-analysis-reporter`)

Once all `research` subagents have completed, invoke `codebase-analysis-reporter` via `invoke_subagent`:

```text
invoke_subagent:
  TypeName: "codebase-analysis-reporter"
  Role: "Codebase Analysis Reporter"
  Prompt: |
    You are the codebase-analysis-reporter. Merge these raw findings into a structured analysis report.
    Open the markdown artifact with the Artifact Summary Contract (## TL;DR, ## Key Decisions, ## Open Questions / Risks).

    Task description: [description]
    Agent roles used: [list of roles]
    Agent count: [N]
    Output path: [task_path]/analysis/[artifact_name]

    ## Raw Findings

    ### [Role 1 Name]
    [paste raw output from agent 1]

    ### [Role 2 Name]
    [paste raw output from agent 2]
```

End your turn to wait for `codebase-analysis-reporter` to finish writing `{task_path}/analysis/{artifact_name}` and reply.

### Step 5: Return Results to Calling Orchestrator

Verify `{task_path}/analysis/{artifact_name}` exists on disk and continue immediately with the calling orchestrator phase using the returned summary, `files_found`, `complexity`, and `risk_level`.
