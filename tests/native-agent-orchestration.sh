#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
STD="$ROOT/.ai/standards/native-agent-orchestration.md"

fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; }

[ -f "$STD" ] || fail "native orchestration standard exists"
grep -q 'Task Router is authoritative' "$STD" || fail "router authority missing"
grep -q 'same implementation/debugging failure occurs twice' "$STD" || fail "retry escalation missing"
grep -q 'Use up to two in parallel' "$STD" || fail "parallel budget missing"
grep -q 'Do not add a duplicate reviewer' "$STD" || fail "duplicate review guard missing"
pass "canonical native orchestration policy"

for entry in \
  "$ROOT/AGENTS.md" \
  "$ROOT/CLAUDE.md" \
  "$ROOT/.cursor/rules/native-agent-orchestration.mdc"; do
  grep -q 'native-agent-orchestration.md' "$entry" || fail "adapter does not reference canonical policy: $entry"
done
pass "Codex/AGENTS, Claude, and Cursor adapters reference canonical policy"

grep -q 'does not require a' "$ROOT/docs/integrations/codex.md" \
  && grep -q 'project-local `.codex/agents/` layer' "$ROOT/docs/integrations/codex.md" \
  || fail "Codex integration should avoid invented .codex/agents requirement"
pass "Codex adapter uses documented AGENTS.md boundary"

printf 'Native orchestration checks passed.\n'
