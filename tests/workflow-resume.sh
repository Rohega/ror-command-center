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

bash -n "$ROOT/lib/rorcc/run_state.sh" "$ROOT/lib/rorcc/workflow.sh" \
  && ok_t "shell syntax" || bad_t "shell syntax"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIX="$TMP/project"
mkdir -p "$FIX/.ai/agents" "$FIX/.ai/workflows" "$FIX/.ai/skills/first" "$FIX/.ai/skills/second"
printf '# first\n' > "$FIX/.ai/skills/first/SKILL.md"
printf '# second\n' > "$FIX/.ai/skills/second/SKILL.md"
cat > "$FIX/.ai/workflows/mini.yaml" <<'EOF'
name: mini
description: resume integration
phases:
  - id: first
    label: First
    skill: first
  - id: second
    label: Second
    skill: second
    depends_on: [first]
EOF

CALLS="$TMP/calls"
FAIL_ONCE="$TMP/fail-once"
: > "$CALLS"
export CALLS FAIL_ONCE

_run_csv_items() {
  local _kind="$1" items="$2" _backend="$3"
  printf '%s\n' "$items" >> "$CALLS"
  if [ "$items" = "second" ] && [ ! -f "$FAIL_ONCE" ]; then
    : > "$FAIL_ONCE"
    return 1
  fi
  return 0
}

if (cd "$FIX" && cmd_workflow mini --auto >/dev/null 2>&1); then
  bad_t "initial workflow should fail on second phase"
else
  ok_t "initial workflow records an incomplete run"
fi

RUN_ID="$(_latest_resumable_run "$FIX")"
if printf '%s\n' "$RUN_ID" | grep -Eq '^[0-9]{8}T[0-9]{6}-[0-9]+$'; then
  ok_t "run id includes timestamp and pid"
else
  bad_t "unexpected run id: $RUN_ID"
fi

STATE="$FIX/.rorcc/runs/$RUN_ID/state.tsv"
META="$FIX/.rorcc/runs/$RUN_ID/metadata.tsv"

[ -f "$META" ] && [ "$(_run_meta_get "$META" workflow)" = "mini" ] \
  && ok_t "run metadata is persisted" || bad_t "run metadata"

FIRST_BEFORE="$(grep -c '^first$' "$CALLS" || true)"
SECOND_BEFORE="$(grep -c '^second$' "$CALLS" || true)"
[ "$FIRST_BEFORE" = "1" ] && [ "$SECOND_BEFORE" = "1" ] \
  && ok_t "first run executed each reached phase once" || bad_t "initial execution counts"

if (cd "$FIX" && cmd_workflow resume latest --auto >/dev/null 2>&1); then
  ok_t "latest incomplete run resumes"
else
  bad_t "resume latest failed"
fi

FIRST_AFTER="$(grep -c '^first$' "$CALLS" || true)"
SECOND_AFTER="$(grep -c '^second$' "$CALLS" || true)"
if [ "$FIRST_AFTER" = "1" ] && [ "$SECOND_AFTER" = "2" ]; then
  ok_t "resume skips passed phase and reruns failed phase"
else
  bad_t "resume counts first=$FIRST_AFTER second=$SECOND_AFTER"
fi

if awk -F'\t' '$1=="first" && $2=="passed" {a=1} $1=="second" && $2=="passed" {b=1} END {exit !(a&&b)}' "$STATE"; then
  ok_t "resumed state reaches passed"
else
  bad_t "resumed state did not pass"
fi

printf '\n# changed definition\n' >> "$FIX/.ai/workflows/mini.yaml"
if (cd "$FIX" && cmd_workflow resume "$RUN_ID" --auto >/dev/null 2>&1); then
  bad_t "resume accepted changed workflow without force"
else
  ok_t "resume blocks changed workflow by default"
fi

if (cd "$FIX" && cmd_workflow resume "$RUN_ID" --auto --force >/dev/null 2>&1); then
  ok_t "explicit force accepts changed workflow"
else
  bad_t "forced resume failed"
fi

printf '\nResult: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
