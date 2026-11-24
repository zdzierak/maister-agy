#!/bin/bash
# Antigravity SessionStart hook for Maister.
# Reads workspace `cwd` from JSON on stdin. When `.maister/tasks` exists in the
# workspace, injects a concise reminder about active orchestrator state and
# mandatory `ask_question` phase gates. Outputs valid JSON on stdout and exits 0.

INPUT=$(cat)

json_field() {
  printf '%s' "$INPUT" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -n 1 \
    | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

CWD=$(json_field cwd)

if [ -n "$CWD" ] && [ -d "$CWD/.maister/tasks" ]; then
  cat <<'EOF'
{
  "injectSteps": [
    {
      "systemMessage": {
        "systemMessage": "Maister workspace detected (.maister/tasks/ exists). If continuing or resuming an orchestrator workflow (including after /compact), read orchestrator-state.yml in the active task directory first to verify completed_phases, and ALWAYS call ask_question at every → MANDATORY GATE regardless of execution mode."
      }
    }
  ]
}
EOF
else
  printf '{}\n'
fi

exit 0
