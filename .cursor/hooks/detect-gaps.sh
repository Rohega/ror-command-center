#!/bin/bash
# RoR Command Center — Cursor sessionStart hook
# Surfaces engineering-gate gaps at the start of a session so the agent
# does not produce plans that skip tests/docs.
# Canonical standards: .ai/standards/project-bootstrap.md, .ai/standards/testing.md

cat >/dev/null 2>&1  # drain stdin

GAPS=""

if [ ! -d ".ai" ]; then
    GAPS="$GAPS\n- .ai/ directory missing — RoR Command Center not installed correctly."
fi

# Rails app present but no test stack -> RSpec not bootstrapped
if [ -f "Gemfile" ]; then
    if [ ! -d "spec" ] && [ ! -d "test" ]; then
        GAPS="$GAPS\n- Rails app without spec/ — bootstrap RSpec first (.ai/standards/project-bootstrap.md)."
    fi
    if ! grep -qE 'rspec-rails' Gemfile 2>/dev/null; then
        GAPS="$GAPS\n- rspec-rails missing from Gemfile — required by project-bootstrap standard."
    fi
    if [ ! -f "README.md" ]; then
        GAPS="$GAPS\n- Rails project without README.md."
    fi
fi

if [ -n "$GAPS" ]; then
    echo -e "RoR Command Center — engineering gate gaps detected:$GAPS" >&2
    echo -e "Plans MUST include tests (RSpec), review, QA, and documentation. See .cursor/rules/workflow-gates.mdc." >&2
fi

exit 0
