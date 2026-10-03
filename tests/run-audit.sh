#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export RORCC_LIB_DIR="$ROOT/lib/rorcc"

# shellcheck source=/dev/null
. "$ROOT/lib/rorcc/common.sh"
# shellcheck source=/dev/null
. "$ROOT/lib/rorcc/runs.sh"

pass=0
fail=0
ok_t(){ printf 'ok - %s\n' "$1"; pass=$((pass+1)); }
bad_t(){ printf 'not ok - %s\n' "$1"; fail=$((fail+1)); }

bash -n "$ROOT/lib/rorcc/runs.sh"   && ok_t "shell syntax" || bad_t "shell syntax"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIX="$TMP/project"
mkdir -p "$FIX/.ai/agents" "$FIX/.rorcc/runs/001" "$FIX/.rorcc/runs/002" "$FIX/.rorcc/runs/003"

cat > "$FIX/.rorcc/runs/001/events.jsonl" <<'EOF'
{"ts":"x","event":"workflow_started","workflow":"mini","run_id":"001","phase":"","unit":"","attempt":"","status":"running","detail":""}
{"ts":"x","event":"workflow_finished","workflow":"mini","run_id":"001","phase":"","unit":"","attempt":"","status":"passed","detail":""}
EOF
cat > "$FIX/.rorcc/runs/002/events.jsonl" <<'EOF'
{"ts":"x","event":"workflow_started","workflow":"mini","run_id":"002","phase":"","unit":"","attempt":"","status":"running","detail":""}
{"ts":"x","event":"verification_finished","workflow":"mini","run_id":"002","phase":"dev","unit":"","attempt":"1","status":"failed","detail":"log"}
{"ts":"x","event":"phase_retry","workflow":"mini","run_id":"002","phase":"dev","unit":"","attempt":"2","status":"retrying","detail":""}
{"ts":"x","event":"phase_finished","workflow":"mini","run_id":"002","phase":"dev","unit":"","attempt":"2","status":"failed","detail":""}
{"ts":"x","event":"workflow_finished","workflow":"mini","run_id":"002","phase":"","unit":"","attempt":"","status":"failed","detail":""}
EOF
cat > "$FIX/.rorcc/runs/003/events.jsonl" <<'EOF'
{"ts":"x","event":"workflow_started","workflow":"mini","run_id":"003","phase":"","unit":"","attempt":"","status":"running","detail":""}
{"ts":"x","event":"phase_retry","workflow":"mini","run_id":"003","phase":"testing","unit":"","attempt":"2","status":"retrying","detail":""}
{"ts":"x","event":"phase_retry","workflow":"mini","run_id":"003","phase":"testing","unit":"","attempt":"3","status":"retrying","detail":""}
{"ts":"x","event":"workflow_finished","workflow":"mini","run_id":"003","phase":"","unit":"","attempt":"","status":"passed","detail":""}
EOF

OUT="$(cd "$FIX" && cmd_runs audit --last 2)"
if printf '%s\n' "$OUT" | grep -Fq 'last 2 traced runs'; then
  ok_t "audit honors --last"
else
  bad_t "audit last limit"
fi

if printf '%s\n' "$OUT" | grep -Fq 'retries:          3'; then
  ok_t "audit counts retries from selected runs"
else
  bad_t "retry count"
fi

if printf '%s\n' "$OUT" | grep -Eq '[[:space:]]+2 testing'; then
  ok_t "audit identifies repeated retry phase"
else
  bad_t "retry phase aggregation"
fi

if printf '%s\n' "$OUT" | grep -Fq 'evidence is still small (2 runs)'; then
  ok_t "small sample does not trigger strong recommendations"
else
  bad_t "small evidence warning"
fi

if (cd "$FIX" && cmd_runs audit --last 0 >/dev/null 2>&1); then
  bad_t "audit accepted invalid --last"
else
  ok_t "audit rejects invalid --last"
fi

EMPTY="$TMP/empty"
mkdir -p "$EMPTY/.ai/agents"
if OUT="$(cd "$EMPTY" && cmd_runs audit 2>&1)" && printf '%s\n' "$OUT" | grep -Fq 'no workflow run evidence found'; then
  ok_t "audit handles projects without run evidence"
else
  bad_t "empty audit handling"
fi

printf '\nResult: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
