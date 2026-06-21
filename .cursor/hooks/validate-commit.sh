#!/bin/bash
# RoR Command Center — Cursor beforeShellExecution hook
# Warns on likely hardcoded secrets in staged files before a commit.
# Canonical standard: .ai/standards/security.md, .ai/standards/git-workflow.md
#
# Non-blocking: always allows, surfaces warnings to the agent.

INPUT=$(cat)

COMMAND=$(printf '%s' "$INPUT" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("command",""))
except Exception:
    pass' 2>/dev/null)
if [ -z "$COMMAND" ]; then
    COMMAND=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

if ! printf '%s' "$COMMAND" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+commit'; then
    echo '{ "permission": "allow" }'
    exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    echo '{ "permission": "allow" }'
    exit 0
fi

WARNINGS=""
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ -f "$file" ] && grep -qiE '(password|secret|api_key|private_key|token)[[:space:]]*=[[:space:]]*['"'"'"][^'"'"'"]+['"'"'"]' "$file" 2>/dev/null; then
        WARNINGS="$WARNINGS $file may contain a hardcoded secret."
    fi
done <<< "$STAGED"

if [ -n "$WARNINGS" ]; then
    MSG="Commit security warning:$WARNINGS Review before committing (see .ai/standards/security.md)."
    printf '{ "permission": "ask", "user_message": "%s", "agent_message": "%s" }\n' "$MSG" "$MSG"
    exit 0
fi

echo '{ "permission": "allow" }'
exit 0
