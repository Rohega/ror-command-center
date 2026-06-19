#!/bin/bash
# RoR Command Center — validate git commits
# Canonical standards: .ai/standards/git-workflow.md

INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+commit'; then
    exit 0
fi

STAGED=$(git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED" ] && exit 0

WARNINGS=""

# Warn on potential secrets in staged files
while IFS= read -r file; do
    if [ -f "$file" ] && grep -qiE '(password|secret|api_key|private_key)\s*=\s*['\''"][^'\''"]+['\''"]' "$file" 2>/dev/null; then
        WARNINGS="$WARNINGS\nSECURITY: $file may contain hardcoded secrets"
    fi
done <<< "$STAGED"

# Validate JSON files
JSON_FILES=$(echo "$STAGED" | grep -E '\.json$' || true)
while IFS= read -r file; do
    [ -z "$file" ] && continue
    if [ -f "$file" ]; then
        if command -v python3 >/dev/null 2>&1; then
            python3 -m json.tool "$file" >/dev/null 2>&1 || WARNINGS="$WARNINGS\nJSON: $file is invalid"
        fi
    fi
done <<< "$JSON_FILES"

if [ -n "$WARNINGS" ]; then
    echo -e "Commit validation warnings:$WARNINGS" >&2
fi

exit 0
