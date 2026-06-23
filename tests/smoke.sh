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
for f in "$RORCC" "$ROOT"/lib/rorcc/*.sh "$ROOT/install.sh" "$ROOT/setup.sh" "$ROOT/.githooks/pre-commit"; do
  if bash -n "$f" 2>/dev/null; then ok "$(basename "$f")"; else bad "$(basename "$f")"; fi
done

printf '\ncommands:\n'
assert_exit 0 "rorcc help"                 -- "$RORCC" help
assert_exit 2 "unknown command -> 2"       -- "$RORCC" frobnicate
assert_exit 2 "init (no arg) -> 2"         -- "$RORCC" init
assert_exit 2 "init bad flag -> 2"         -- "$RORCC" init --bogus
assert_exit 2 "init --docker (no dir) -> 2" -- "$RORCC" init --docker
assert_exit 2 "build-agent (no arg) -> 2"  -- "$RORCC" build-agent
assert_exit 1 "build-agent bad name -> 1"  -- "$RORCC" build-agent does-not-exist
assert_exit 2 "agent (no arg) -> 2"        -- "$RORCC" agent
assert_exit 2 "agent bad flag -> 2"        -- "$RORCC" agent rails-architect --bogus
# Cloud without credentials/jq must fail cleanly (exit 1), never hang.
assert_exit 1 "agent --cloud (no key) -> 1" -- env -u OPENAI_API_KEY -u ANTHROPIC_API_KEY "$RORCC" agent rails-architect --cloud
# Proxy prints config and exits 0 (no --start, so it never launches a server).
assert_exit 0 "proxy (info only) -> 0"     -- "$RORCC" proxy
assert_exit 2 "proxy bad flag -> 2"        -- "$RORCC" proxy --bogus
assert_exit 2 "skill (no arg) -> 2"        -- "$RORCC" skill
assert_exit 1 "skill bad name -> 1"        -- "$RORCC" skill does-not-exist
assert_exit 2 "skill bad flag -> 2"        -- "$RORCC" skill create-feature-spec --bogus
assert_exit 2 "workflow (no arg) -> 2"     -- "$RORCC" workflow
assert_exit 1 "workflow bad name -> 1"     -- "$RORCC" workflow does-not-exist
assert_exit 2 "workflow bad flag -> 2"     -- "$RORCC" workflow new-feature --bogus

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

printf '\ninstall.sh excludes archive/:\n'
INSTOUT="$(cd "$ROOT" && ./install.sh --dry-run "$(mktemp -d)" 2>&1)"
printf '%s\n' "$INSTOUT" | grep -qi 'archive/' && bad "archive/ leaked into install" || ok "archive/ not copied"
printf '%s\n' "$INSTOUT" | grep -q '\.ai/' && ok ".ai/ is copied (sanity)" || bad ".ai/ missing from install"

printf '\nollama_has_model (matches with/without tag):\n'
# Run in an isolated bash so common.sh's ok()/err() don't clobber this file's.
# Stub `ollama list` with a fixture mimicking real output (header + "name:latest").
check_model() {
  OLLAMA_FIXTURE='NAME	ID	SIZE
rorcc-product-owner:latest	a1	4.7 GB
qwen2.5-coder:7b	b2	4.7 GB' \
  bash -c '. "$1/lib/rorcc/common.sh"; ollama() { printf "%s\n" "$OLLAMA_FIXTURE"; }; ollama_has_model "$2"' _ "$ROOT" "$1"
}
assert_exit 0 "untagged agent name matches :latest" -- check_model "rorcc-product-owner"
assert_exit 0 "tagged base model matches"           -- check_model "qwen2.5-coder:7b"
assert_exit 1 "absent model does not match"         -- check_model "rorcc-nope"

printf '\nworkflow parsing:\n'
WFOUT="$(cd "$ROOT" && bash -c '. lib/rorcc/workflow.sh; _parse_phases .ai/workflows/new-feature.yaml')"
nlines="$(printf '%s\n' "$WFOUT" | grep -c .)"
[ "$nlines" -eq 8 ] && ok "new-feature parses 8 phases" || bad "phase count = $nlines (expected 8)"
printf '%s\n' "$WFOUT" | awk -F'\t' 'NR==1{exit !($1=="Idea" && $2=="product-owner" && $3=="create-feature-spec")}' \
  && ok "phase 1 = Idea/product-owner/create-feature-spec" || bad "phase 1 fields"

printf '\n'
printf '\033[1mResult:\033[0m %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
