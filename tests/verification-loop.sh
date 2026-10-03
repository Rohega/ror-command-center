#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export RORCC_LIB_DIR="$ROOT/lib/rorcc"

# shellcheck source=/dev/null
. "$ROOT/lib/rorcc/common.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/rorcc/workflow.sh"

pass=0
fail=0
ok_t(){ printf 'ok - %s\n' "$1"; pass=$((pass+1)); }
bad_t(){ printf 'not ok - %s\n' "$1"; fail=$((fail+1)); }

bash -n "$ROOT/lib/rorcc/verify.sh" "$ROOT/lib/rorcc/workflow.sh"   && ok_t "shell syntax" || bad_t "shell syntax"

mapfile -t cfg < <(_phase_verification "$ROOT/.ai/workflows/new-feature.yaml" development)
[ "${cfg[0]:-}" = "auto" ] && [ "${cfg[1]:-}" = "2" ]   && ok_t "development declares auto verification with two attempts"   || bad_t "development verification metadata"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/verify.log"

RORCC_VERIFY_CMD=true _verify_phase "$TMP" auto "$LOG" >/dev/null 2>&1   && ok_t "explicit deterministic verifier can pass"   || bad_t "passing verifier"

if RORCC_VERIFY_CMD=false _verify_phase "$TMP" auto "$LOG" >/dev/null 2>&1; then
  bad_t "failing verifier returned success"
else
  ok_t "explicit deterministic verifier can fail"
fi

mkdir -p "$TMP/tests"
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/tests/smoke.sh"
chmod +x "$TMP/tests/smoke.sh"
[ "$(_verify_auto_command "$TMP")" = "bash tests/smoke.sh" ]   && ok_t "auto verifier prefers an existing smoke test"   || bad_t "auto smoke detection"

BAD="$TMP/bad.yaml"
cat > "$BAD" <<'EOF'
name: bad
phases:
  - id: dev
    label: Dev
    skill: dummy
    verify: auto
    max_attempts: 4
EOF
mkdir -p "$TMP/.ai/skills/dummy"
printf '# dummy\n' > "$TMP/.ai/skills/dummy/SKILL.md"
if _preflight_workflow "$BAD" "$TMP" >/dev/null 2>&1; then
  bad_t "preflight accepted an unbounded retry count"
else
  ok_t "preflight rejects retry counts above three"
fi

FIX="$TMP/integration"
mkdir -p "$FIX/.ai/workflows" "$FIX/.ai/skills/dummy"
printf '# dummy\n' > "$FIX/.ai/skills/dummy/SKILL.md"
cat > "$FIX/.ai/workflows/mini.yaml" <<'EOF'
name: mini
description: retry integration
phases:
  - id: dev
    label: Development
    skill: dummy
    verify: auto
    max_attempts: 2
EOF

RUN_COUNT="$TMP/run-count"
VERIFY_COUNT="$TMP/verify-count"
: > "$RUN_COUNT"
: > "$VERIFY_COUNT"
export RUN_COUNT VERIFY_COUNT

_run_csv_items() {
  printf 'run\n' >> "$RUN_COUNT"
  return 0
}
_verify_phase() {
  local _root="$1" _mode="$2" output="$3"
  printf 'verify\n' >> "$VERIFY_COUNT"
  printf 'deterministic check\n' > "$output"
  [ "$(wc -l < "$VERIFY_COUNT" | tr -d ' ')" -ge 2 ]
}

if (cd "$FIX" && cmd_workflow mini --auto >/dev/null 2>&1); then
  runs="$(wc -l < "$RUN_COUNT" | tr -d ' ')"
  verifies="$(wc -l < "$VERIFY_COUNT" | tr -d ' ')"
  if [ "$runs" = "2" ] && [ "$verifies" = "2" ]; then
    ok_t "failed verification triggers exactly one bounded retry"
  else
    bad_t "retry counts runs=$runs verifies=$verifies"
  fi
else
  bad_t "integration workflow failed"
fi

printf '\nResult: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
