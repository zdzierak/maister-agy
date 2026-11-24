---
name: maister-work
description: >-
  Unified Maister entry point — detects existing tasks to resume or auto-classifies new tasks and routes to the right workflow (maister-development, maister-performance, maister-migration, maister-research, or maister-product-design).
---

# Unified Work Entry Point (`/maister-work`)

Auto-classifies tasks and routes to the appropriate Maister workflow orchestrator. Supports resuming existing tasks in `.maister/tasks/` or starting new ones from a description, conversation context, or issue reference.

## Usage

```text
/maister-work [task description | task folder path | issue identifier]
```

### Input Types

| Input Type | Example |
|------------|---------|
| Task folder path | `.maister/tasks/development/2026-10-23-login-timeout` |
| Folder name only | `2026-10-26-user-auth` (searches all `.maister/tasks/*/` types) |
| Task description | `"Fix login timeout error on mobile"` |
| GitHub issue | `#456`, `GH-456`, `https://github.com/owner/repo/issues/456` |
| Jira ticket | `PROJ-456`, `https://company.atlassian.net/browse/PROJ-456` |
| Azure DevOps | `AB#123`, `https://dev.azure.com/org/project/_workitems/edit/123` |
| No argument | Extracts context from current conversation or asks via `ask_question` |

## Workflow Type Routing

| Classification | Target Skill (`SKILL.md` to read & execute) |
|----------------|---------------------------------------------|
| `development` | `../maister-development/SKILL.md` |
| `performance` | `../maister-performance/SKILL.md` |
| `migration` | `../maister-migration/SKILL.md` |
| `research` | `../maister-research/SKILL.md` |
| `product-design` | `../maister-product-design/SKILL.md` |

---

## Execution Steps

### Step 1: Parse Input and Detect Existing Task Folder

1. If an argument is provided, check if it resolves to an existing directory containing `orchestrator-state.yml`:
   - Path as-is
   - Prepending `.maister/`
   - Searching `.maister/tasks/*/<input>`
2. **If an existing task folder with `orchestrator-state.yml` is found** → go to **Step 2: Resume Existing Task**.
3. **If no argument is provided**:
   - Check recent conversation turns for an already-discussed task or bug.
   - If none exists in conversation, ask the user what they would like to work on.
4. **Otherwise** → go to **Step 3: Classify & Route New Task**.

### Step 2: Resume Existing Task

1. Read `orchestrator-state.yml` from the detected task folder.
2. Map folder category to workflow skill:
   - `development/` → `maister-development`
   - `performance/` → `maister-performance`
   - `migrations/` → `maister-migration`
   - `research/` → `maister-research`
   - `product-design/` → `maister-product-design`
3. Inspect `task.status`, `completed_phases`, and `failed_phases`, then use `ask_question` to confirm how to proceed:
   - **In-progress**: `["(Recommended) Resume from next incomplete phase", "Restart from specific phase", "Cancel"]`
   - **Completed**: `["(Recommended) View task summary", "Create follow-up development task", "Re-run verification phase", "Cancel"]`
   - **Failed**: `["(Recommended) Resume with fresh attempts (--reset-attempts)", "Retry failed phase", "Restart from specific phase", "Cancel"]`
4. Read `../<target-skill>/SKILL.md` using `read_file` and execute its resume flow with `[task_path]` and any selected flags.

### Step 3: Classify & Route New Task

1. **Invoke the `task-classifier` subagent** via `invoke_subagent`:
   ```text
   invoke_subagent:
     TypeName: "task-classifier"
     Role: "Task Classifier"
     Prompt: |
       Classify this task into one of the 5 Maister workflow types (development, performance, migration, research, product-design):
       Task input: [task description or issue reference]
       Analyze codebase/issue context as needed and return structured YAML with task_type, confidence (0-100), keywords_matched, and reasoning. Do NOT ask the user questions directly — return your classification so the main agent can confirm with the user.
   ```
   End your turn after calling `invoke_subagent` so Antigravity wakes you when `task-classifier` finishes.

2. **Confirm classification with the user via `ask_question`**:
   - **High confidence (>= 80%)**: Present the detected workflow type, confidence, and brief reasoning, then call `ask_question` with:
     `["(Recommended) Proceed with [task_type] workflow", "Choose a different workflow type", "Cancel"]`
   - **Medium/Low confidence (< 80%) or classification error**: Present findings and call `ask_question` with all 5 workflow options:
     - `Development — Features, enhancements, bug fixes, refactoring`
     - `Performance — Bottleneck analysis and speed/resource optimization`
     - `Migration — Framework, database, or architecture transitions`
     - `Research — Multi-source investigation, synthesis, and ADR design`
     - `Product Design — Interactive problem exploration, specs, and UI mockups`

3. **Route to the chosen orchestrator**:
   Read `../maister-[chosen-type]/SKILL.md` using `read_file` and immediately execute its initialization and workflow phases in the main agent context with the task description!
