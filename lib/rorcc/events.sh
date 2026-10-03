#!/usr/bin/env bash
# Minimal append-only workflow event trace. Sourced by workflow.sh.

_json_escape() {
  local s="${1:-}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

_event_emit() {
  local file="$1" event="$2" workflow="${3:-}" run_id="${4:-}"
  local phase="${5:-}" unit="${6:-}" attempt="${7:-}" status="${8:-}" detail="${9:-}"
  local ts
  [ -n "$file" ] || return 0
  ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf '{"ts":"%s","event":"%s","workflow":"%s","run_id":"%s","phase":"%s","unit":"%s","attempt":"%s","status":"%s","detail":"%s"}\n' \
    "$(_json_escape "$ts")" \
    "$(_json_escape "$event")" \
    "$(_json_escape "$workflow")" \
    "$(_json_escape "$run_id")" \
    "$(_json_escape "$phase")" \
    "$(_json_escape "$unit")" \
    "$(_json_escape "$attempt")" \
    "$(_json_escape "$status")" \
    "$(_json_escape "$detail")" >> "$file"
}
