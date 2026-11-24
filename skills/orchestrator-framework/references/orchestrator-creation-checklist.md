# Orchestrator Creation Checklist (Antigravity)

Use when creating NEW orchestrators or auditing existing ones. Not loaded during normal orchestrator execution.

---

## Required Elements

Before considering an orchestrator complete, verify ALL items:

- [ ] **Size Budget (`< 24,000` bytes)** — `SKILL.md` body MUST stay under 24,000 bytes (`agy plugin validate --strict`); place detailed phase instructions in `references/workflow-phases.md` (< 45,000 bytes) and load it explicitly during Initialization
- [ ] **Step 0 & Step 1: Load Framework** — Settle `→ MANDATORY GATE` policy once at entry and read `../orchestrator-framework/references/orchestrator-patterns.md` + `references/workflow-phases.md`
- [ ] **State file creation** — Explicit step to capture UTC clock via `date -u +"%Y-%m-%dT%H:%M:%SZ"` (`run_command`) and create `orchestrator-state.yml`
- [ ] **Phase structure** — Each phase has: Purpose, Execute, Output, State, Transition (`→ MANDATORY GATE` / `→ AUTO-CONTINUE`)
- [ ] **Delegation enforcement** — Skills are executed by reading `../<skill>/SKILL.md` in main agent context; subagents are spawned via `invoke_subagent` (`TypeName`, `Role`, `Prompt`) with async wakeup
- [ ] **POST-CONTINUATION blocks** — After internal skill phases, explicit instructions to re-read `orchestrator-state.yml`, update `completed_phases` (after exit gate), and continue
- [ ] **Context passing** — All subagent prompts include accumulated context, `phase_summaries`, and the § 7 Artifact Summary Contract
- [ ] **Decision gates** — Phases receiving `decisions_needed` present each decision via `ask_question`
- [ ] **Interactive mode** — `ask_question` called at every `→ MANDATORY GATE` transition with `(Recommended)` on recommended default
- [ ] **Standards discovery** — `.maister/docs/INDEX.md` referenced in spec, plan, implement, and verify phases
- [ ] **Progress tracking (`update_steps`)** — `update_steps` called at workflow start (up to 12 concise steps) and updated at phase transitions, paired with `orchestrator-state.yml` as persistent disk state
- [ ] **Dashboard upkeep** — Every orchestrator-owned rewrite moment in `orchestrator-patterns.md` § 8 is implemented
- [ ] **Finalization reconciliation** — Closing phase compares `artifacts[]` in state against disk and names every missing path in the summary (`orchestrator-patterns.md` § 10)
- [ ] **Auto-recovery table & Domain context schema** — Documented clearly
