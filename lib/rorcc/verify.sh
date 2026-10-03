#!/usr/bin/env bash
# Deterministic workflow verification. Sourced by workflow.sh.

_verify_auto_command() {
  local root="$1"

  if [ -n "${RORCC_VERIFY_CMD:-}" ]; then
    printf '%s\n' "$RORCC_VERIFY_CMD"
    return 0
  fi

  if [ -f "$root/tests/smoke.sh" ]; then
    printf '%s\n' "bash tests/smoke.sh"
    return 0
  fi

  if [ -f "$root/Gemfile" ]; then
    if [ -d "$root/spec" ] && { [ -f "$root/.rspec" ] || grep -Eq 'rspec(-rails)?' "$root/Gemfile"; }; then
      printf '%s\n' "bundle exec rspec"
      return 0
    fi

    if [ -d "$root/test" ]; then
      if [ -x "$root/bin/rails" ]; then
        printf '%s\n' "bin/rails test"
      else
        printf '%s\n' "bundle exec rails test"
      fi
      return 0
    fi
  fi

  printf '\n'
}

_verify_phase() {
  local root="$1" mode="${2:-}" output_file="$3"
  local cmd=""

  : > "$output_file"

  case "$mode" in
    ""|none)
      return 0
      ;;
    auto)
      cmd="$(_verify_auto_command "$root")"
      if [ -z "$cmd" ]; then
        info "verification: no deterministic check detected — skipped"
        printf '%s\n' "verification skipped: no deterministic check detected" > "$output_file"
        return 0
      fi
      ;;
    command:*)
      cmd="${mode#command:}"
      ;;
    *)
      err "unknown verification mode: $mode"
      printf '%s\n' "unknown verification mode: $mode" > "$output_file"
      return 2
      ;;
  esac

  info "verification: $cmd"
  if (cd "$root" && bash -lc "$cmd") > "$output_file" 2>&1; then
    ok "verification passed"
    return 0
  fi

  warn "verification failed"
  cat "$output_file"
  return 1
}
