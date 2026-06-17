#!/bin/bash
# Rolos — session start context

echo "=== Rolos AI Development Studio ==="
echo "Canonical definitions: .ai/"
echo "Collaboration: .ai/standards/collaboration.md"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
    echo "Branch: $BRANCH"
    echo ""
    echo "Recent commits:"
    git log --oneline -5 2>/dev/null | while read -r line; do echo "  $line"; done
fi

if [ -f "docs/specs" ] || ls docs/specs/*.md >/dev/null 2>&1; then
    echo ""
    echo "Feature specs: docs/specs/"
fi

exit 0
