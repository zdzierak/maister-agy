#!/bin/bash
# Antigravity PreToolUse hook for `run_command`.
# Guards against destructive git/filesystem commands (`git stash`, `git reset --hard`,
# `git checkout .`, `git clean`, `git push --force`, `rm -rf` outside /tmp) that could
# clobber uncommitted changes or parallel `task-group-implementer` waves.
#
# Uses `"decision": "force_ask"` so background subagents in `auto` mode cannot
# silently execute destructive commands, while still allowing a human user to
# explicitly confirm if they requested the command intentionally.
# Returns `{}` on non-matching commands so normal user permissions apply unchanged.

INPUT=$(cat)

json_field() {
  printf '%s' "$INPUT" \
    | grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" \
    | head -n 1 \
    | sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//"
}

COMMAND=$(json_field CommandLine | sed -E 's/\\[ntr]/ /g')

if [ -z "$COMMAND" ]; then
  printf '{}\n'
  exit 0
fi

# Destructive git commands
if printf '%s' "$COMMAND" | grep -qEi 'git[[:space:]]+stash|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+checkout[[:space:]]+--[[:space:]]+\.|git[[:space:]]+checkout[[:space:]]+\.[[:space:]]*$|git[[:space:]]+clean|git[[:space:]]+push[[:space:]]+(-f|--force)'; then
  cat <<'EOF'
{
  "decision": "force_ask",
  "reason": "Maister safety guard: Destructive git command detected (stash, reset --hard, checkout ., clean, or push --force). Reject if initiated by a background subagent during an implementation wave."
}
EOF
  exit 0
fi

# Destructive rm -rf (allow /tmp cleanup used by temporary discovery directories)
if printf '%s' "$COMMAND" | grep -qEi 'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f|rm[[:space:]]+-[a-zA-Z]*f[a-zA-Z]*r'; then
  if ! printf '%s' "$COMMAND" | grep -qE '^[[:space:]]*rm[[:space:]]+-rf[[:space:]]+(/tmp/|"\$TMPDIR"|/var/folders/)'; then
    cat <<'EOF'
{
  "decision": "force_ask",
  "reason": "Maister safety guard: Recursive force delete (rm -rf) detected. Confirm before allowing execution."
}
EOF
    exit 0
  fi
fi

printf '{}\n'
exit 0
