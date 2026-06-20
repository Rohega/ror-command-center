#!/usr/bin/env bash
# RoR Command Center — rorcc CLI smoke tests.
# No Ollama or jq required: validates syntax, help, build-agent codegen, and
# error handling. Run from anywhere: tests/smoke.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
RORCC="$ROOT/cli/rorcc"

PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }

# assert_exit <expected> <desc> -- <command...>
assert_exit() {
  local expected="$1" desc="$2"; shift 2; shift  # drop the "--"
  "$@" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$expected" ]; then ok "$desc"; else bad "$desc (exit $rc, expected $expected)"; fi
}

printf '\033[1mrorcc smoke tests\033[0m\n\n'

printf 'syntax (bash -n):\n'
for f in "$RORCC" "$ROOT"/lib/rorcc/*.sh "$ROOT/install.sh" "$ROOT/setup.sh"; do
  if bash -n "$f" 2>/dev/null; then ok "$(basename "$f")"; else bad "$(basename "$f")"; fi
done

printf '\ncommands:\n'
assert_exit 0 "rorcc help"                 -- "$RORCC" help
assert_exit 2 "unknown command -> 2"       -- "$RORCC" frobnicate
assert_exit 2 "build-agent (no arg) -> 2"  -- "$RORCC" build-agent
assert_exit 1 "build-agent bad name -> 1"  -- "$RORCC" build-agent does-not-exist
assert_exit 2 "agent (no arg) -> 2"        -- "$RORCC" agent
assert_exit 2 "agent bad flag -> 2"        -- "$RORCC" agent rails-architect --bogus
# Cloud without credentials/jq must fail cleanly (exit 1), never hang.
assert_exit 1 "agent --cloud (no key) -> 1" -- env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY "$RORCC" agent rails-architect --cloud
# Proxy prints config and exits 0 (no --start, so it never launches a server).
assert_exit 0 "proxy (info only) -> 0"     -- "$RORCC" proxy
assert_exit 2 "proxy bad flag -> 2"        -- "$RORCC" proxy --bogus

printf '\nbuild-agent codegen (no Ollama needed):\n'
TMP="$(mktemp -d)"; export HOME="$TMP"
if (cd "$ROOT" && "$RORCC" build-agent rails-architect >/dev/null 2>&1); then
  mf="$ROOT/.rorcc/build/rails-architect/Modelfile"
  [ -f "$mf" ] && ok "Modelfile generated" || bad "Modelfile missing"
  grep -q '^FROM ' "$mf" 2>/dev/null && ok "Modelfile has FROM" || bad "Modelfile missing FROM"
  grep -q 'ROLE DEFINITION' "$mf" 2>/dev/null && ok "Modelfile inlines role" || bad "role not inlined"
else
  bad "build-agent rails-architect failed"
fi
rm -rf "$ROOT/.rorcc" "$TMP"

printf '\n'
printf '\033[1mResult:\033[0m %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
