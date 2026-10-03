#!/usr/bin/env bash
# Read-only summaries of local RORCC workflow run evidence.

_runs_usage() {
  cat <<'EOF'
usage:
  rorcc runs audit [--last N]

Reads local .rorcc/runs/*/events.jsonl only. It never changes workflows,
prompts, routing rules, or run state.
EOF
}

cmd_runs() {
  local sub="${1:-}"
  [ $# -gt 0 ] && shift || true
  case "$sub" in
    audit) _cmd_runs_audit "$@" ;;
    ""|-h|--help|help) _runs_usage ;;
    *) err "unknown runs command: $sub"; _runs_usage; return 2 ;;
  esac
}

_cmd_runs_audit() {
  local last=20
  while [ $# -gt 0 ]; do
    case "$1" in
      --last)
        shift
        case "${1:-}" in
          ''|*[!0-9]*) err "usage: --last N"; return 2 ;;
        esac
        [ "$1" -ge 1 ] && [ "$1" -le 100 ] || { err "--last must be 1..100"; return 2; }
        last="$1"
        ;;
      -*) err "unknown audit option: $1"; return 2 ;;
      *) err "unexpected audit argument: $1"; return 2 ;;
    esac
    shift
  done

  local root runs_root tmp run id file
  local total=0 passed=0 failed=0 incomplete=0 retries=0 verify_failed=0 phase_failed=0
  root="$(require_ai_root)" || return 1
  runs_root="$root/.rorcc/runs"
  [ -d "$runs_root" ] || {
    info "no workflow run evidence found"
    return 0
  }

  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  : > "$tmp"

  while IFS= read -r id; do
    [ -n "$id" ] || continue
    file="$runs_root/$id/events.jsonl"
    [ -f "$file" ] || continue
    printf '%s\n' "$file" >> "$tmp"
    total=$((total + 1))

    if grep -Fq '"event":"workflow_finished"' "$file"; then
      if grep -F '"event":"workflow_finished"' "$file" | tail -n 1 | grep -Fq '"status":"passed"'; then
        passed=$((passed + 1))
      else
        failed=$((failed + 1))
      fi
    else
      incomplete=$((incomplete + 1))
    fi

    run="$(grep -Fc '"event":"phase_retry"' "$file" || true)"
    retries=$((retries + run))
    run="$(grep -F '"event":"verification_finished"' "$file" | grep -Fc '"status":"failed"' || true)"
    verify_failed=$((verify_failed + run))
    run="$(grep -F '"event":"phase_finished"' "$file" | grep -Fc '"status":"failed"' || true)"
    phase_failed=$((phase_failed + run))

    [ "$total" -ge "$last" ] && break
  done < <(ls -1 "$runs_root" 2>/dev/null | sort -r)

  [ "$total" -gt 0 ] || {
    info "no workflow event traces found"
    return 0
  }

  printf 'RORCC run audit (last %s traced runs)\n' "$total"
  printf '  completed passed: %s\n' "$passed"
  printf '  completed failed: %s\n' "$failed"
  printf '  incomplete:       %s\n' "$incomplete"
  printf '  retries:          %s\n' "$retries"
  printf '  verifier failures:%s\n' "$verify_failed"
  printf '  phase failures:   %s\n' "$phase_failed"

  if [ "$retries" -gt 0 ]; then
    printf '\nPhases with retries:\n'
    while IFS= read -r run; do
      [ -n "$run" ] && printf '  %s\n' "$run"
    done < <(
      while IFS= read -r file; do
        sed -n 's/.*"event":"phase_retry".*"phase":"\([^"]*\)".*/\1/p' "$file"
      done < "$tmp" | sort | uniq -c | sort -rn | head -5
    )
  fi

  printf '\n'
  if [ "$total" -lt 5 ]; then
    warn "evidence is still small ($total runs); do not change router/skills from this audit alone"
  else
    info "evidence threshold reached; use repeated patterns as input for a human-reviewed change"
  fi
}
