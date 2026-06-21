#!/bin/bash
# RoR Command Center — Cursor beforeShellExecution hook
# Blocks direct push to protected branches (PR only).
# Canonical standard: .ai/standards/git-workflow.md
#
# beforeShellExecution input: { "command": "git push origin main", ... }
# Output: JSON with "permission" ("allow" | "deny").

INPUT=$(cat)

# Parse .command (python3 first, grep fallback). jq is not assumed to exist.
COMMAND=$(printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("command",""))
except Exception:
    pass' 2>/dev/null)
if [ -z "$COMMAND" ]; then
    COMMAND=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only act on git push
if ! printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+push'; then
    echo '{ "permission": "allow" }'
    exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
MATCHED=""
for branch in develop main master; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        MATCHED="$branch"; break
    fi
    if printf '%s' "$COMMAND" | grep -qE "[[:space:]]${branch}([[:space:]]|$)"; then
        MATCHED="$branch"; break
    fi
done

if [ -n "$MATCHED" ]; then
    if [ "${RORCC_ALLOW_PROTECTED_PUSH:-0}" = "1" ]; then
        echo '{ "permission": "allow", "agent_message": "Protected-branch push allowed via RORCC_ALLOW_PROTECTED_PUSH override." }'
        exit 0
    fi
    echo '{
      "permission": "deny",
      "user_message": "Blocked: direct push to protected branch '"'$MATCHED'"' is not allowed. Open a PR instead (see .ai/standards/git-workflow.md). Override: RORCC_ALLOW_PROTECTED_PUSH=1.",
      "agent_message": "Push to protected branch '"'$MATCHED'"' is blocked by policy. Use a feature branch and open a pull request."
    }'
    exit 0
fi

echo '{ "permission": "allow" }'
exit 0
