#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REAL_LIB="$ROOT/lib/rorcc"
export RORCC_LIB_DIR="$REAL_LIB"

# shellcheck source=/dev/null
. "$REAL_LIB/common.sh"
# shellcheck source=/dev/null
. "$REAL_LIB/workflow.sh"

pass=0
fail=0
ok_t(){ printf 'ok - %s\n' "$1"; pass=$((pass+1)); }
bad_t(){ printf 'not ok - %s\n' "$1"; fail=$((fail+1)); }

bash -n "$REAL_LIB/events.sh" "$REAL_LIB/workflow.sh"   && ok_t "shell syntax" || bad_t "shell syntax"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
EVENTS="$TMP/events.jsonl"

_event_emit "$EVENTS" "sample" "wf" "run-1" "dev" "unit" "1" "passed" 'quote " slash \ tab'
if grep -Fq '"event":"sample"' "$EVENTS" && grep -Fq '\"' "$EVENTS" && grep -Fq '\\' "$EVENTS"; then
  ok_t "event JSON escapes quotes and backslashes"
else
  bad_t "event escaping"
fi

FAKE="$TMP/fake-lib"
mkdir -p "$FAKE"
cat > "$FAKE/skill.sh" <<'EOF'
cmd_skill() { return 0; }
EOF
RORCC_LIB_DIR="$FAKE"
RORCC_EVENT_FILE="$EVENTS"
RORCC_EVENT_WORKFLOW="mini"
RORCC_EVENT_RUN_ID="run-2"
RORCC_EVENT_PHASE="dev"
RORCC_EVENT_ATTEMPT="1"
if _run_csv_items skill "one,two" ""; then
  starts="$(grep -c '"event":"unit_started"' "$EVENTS" || true)"
  finishes="$(grep -c '"event":"unit_finished"' "$EVENTS" || true)"
  [ "$starts" = "2" ] && [ "$finishes" = "2" ]     && ok_t "unit execution emits start and finish events"     || bad_t "unit event counts starts=$starts finishes=$finishes"
else
  bad_t "unit trace execution failed"
fi
RORCC_LIB_DIR="$REAL_LIB"

FIX="$TMP/project"
mkdir -p "$FIX/.ai/agents" "$FIX/.ai/workflows" "$FIX/.ai/skills/dummy"
printf '# dummy\n' > "$FIX/.ai/skills/dummy/SKILL.md"
cat > "$FIX/.ai/workflows/mini.yaml" <<'EOF'
name: mini
description: trace integration
phases:
  - id: dev
    label: Development
    skill: dummy
    verify: auto
    max_attempts: 2
EOF

COUNT="$TMP/verify-count"
: > "$COUNT"
_run_csv_items() { return 0; }
_verify_phase() {
  local _root="$1" _mode="$2" output="$3"
  printf 'v\n' >> "$COUNT"
  printf 'check\n' > "$output"
  [ "$(wc -l < "$COUNT" | tr -d ' ')" -ge 2 ]
}

if (cd "$FIX" && cmd_workflow mini --auto >/dev/null 2>&1); then
  ok_t "workflow with retry completes"
else
  bad_t "workflow trace integration failed"
fi

RUN_ID="$(_latest_resumable_run "$FIX")"
TRACE="$FIX/.rorcc/runs/$RUN_ID/events.jsonl"
if [ -f "$TRACE" ]   && grep -Fq '"event":"workflow_started"' "$TRACE"   && grep -Fq '"event":"phase_started"' "$TRACE"   && grep -Fq '"event":"verification_finished"' "$TRACE"   && grep -Fq '"event":"phase_retry"' "$TRACE"   && grep -Fq '"event":"phase_finished"' "$TRACE"   && grep -Fq '"event":"workflow_finished"' "$TRACE"; then
  ok_t "workflow trace contains lifecycle and retry evidence"
else
  bad_t "workflow lifecycle trace incomplete"
fi

lines_before="$(wc -l < "$TRACE" | tr -d ' ')"
if (cd "$FIX" && cmd_workflow resume "$RUN_ID" --auto >/dev/null 2>&1); then
  lines_after="$(wc -l < "$TRACE" | tr -d ' ')"
  if [ "$lines_after" -gt "$lines_before" ] && tail -n "$((lines_after-lines_before))" "$TRACE" | grep -Fq '"event":"workflow_resumed"'; then
    ok_t "resume appends to the same event trace"
  else
    bad_t "resume did not append workflow_resumed"
  fi
else
  bad_t "resume trace integration failed"
fi

printf '\nResult: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
