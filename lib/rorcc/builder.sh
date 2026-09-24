# shellcheck shell=bash
# rorcc builder — phase 1. Fixed questions, plain-language plan, then new-feature.
# No model. See docs/design/app-builder.md and ADR-0006.

_builder_yes() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    y|yes|sí|si) return 0 ;;
    *) return 1 ;;
  esac
}

_builder_secret() {
  printf '%s' "$1" | grep -Eqi 'password|secret|api[_-]?key|[[:space:]]token[[:space:]]|^token[[:space:]]|bearer[[:space:]]+|sk-[A-Za-z0-9]'
}

# _builder_route <request> <data yes|no> <signin yes|no> <area new|change>
# Sets BUILDER_SIZE and BUILDER_SIGNALS. Size only moves up. Signals accumulate.
_builder_route() {
  local request="$1" data="$2" signin="$3" area="$4"
  local size="M" signals=""
  if _builder_yes "$signin"; then
    signals="${signals:+$signals,}auth_changed"
  fi
  if _builder_yes "$data"; then
    signals="${signals:+$signals,}database_changed"
  fi
  if [ "$area" = "new" ]; then
    size="L"
    signals="${signals:+$signals,}user_behavior_changed"
  elif printf '%s' "$request" | grep -Eqi 'page|screen|pantalla|flow|flujo|form|formulario|button|bot[oó]n'; then
    signals="${signals:+$signals,}user_behavior_changed"
  fi
  BUILDER_SIZE="$size"
  BUILDER_SIGNALS="${signals:-none}"
}

_builder_command() {
  local request="$1" cmd
  cmd="rorcc workflow new-feature --size $BUILDER_SIZE --request $(printf '%q' "$request")"
  if [ "$BUILDER_SIGNALS" != "none" ]; then
    cmd="$cmd --signals $BUILDER_SIGNALS"
  fi
  printf '%s\n' "$cmd"
}

_builder_ask() {
  local prompt="$1" reply=""
  while true; do
    printf '%s ' "$prompt" >&2
    IFS= read -r reply || return 1
    if _builder_secret "$reply"; then
      err "that looks like a secret — answer without passwords or tokens"
      continue
    fi
    printf '%s\n' "$reply"
    return 0
  done
}

_builder_write_plan() {
  local path="$1" request="$2" who="$3" data="$4" signin="$5" done_when="$6"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
# Builder plan

- Request: $request
- Who uses it: $who
- Data: $data
- Sign-in: $signin
- Done when: $done_when

## Routing

- size: $BUILDER_SIZE
- signals: $BUILDER_SIGNALS
EOF
}

cmd_builder() {
  local plan_only=0 accept=0 request="" who="" data="" signin="" area="" done_when=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --plan) plan_only=1 ;;
      --accept) accept=1 ;;
      --request) shift; [ -n "${1:-}" ] || { err "usage: --request <text>"; return 2; }; request="$1" ;;
      --who) shift; [ -n "${1:-}" ] || { err "usage: --who <role>"; return 2; }; who="$1" ;;
      --data) shift; data="${1:-}" ;;
      --sign-in) shift; signin="${1:-}" ;;
      --area) shift; area="${1:-}" ;;
      --done) shift; [ -n "${1:-}" ] || { err "usage: --done <sentence>"; return 2; }; done_when="$1" ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) err "unexpected argument: $1"; return 2 ;;
    esac
    shift
  done

  local root; root="$(require_ai_root)" || return 1
  local stamp path
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  path="$root/docs/plans/builder-$stamp.md"

  if [ "$plan_only" -eq 1 ]; then
    printf 'questions:\n'
    printf '  1. Who uses this, in one role name?\n'
    printf '  2. Does it store or change data? (yes / no)\n'
    printf '  3. Does it sign someone in or check a permission? (yes / no)\n'
    printf '  4. Is this a new area of the app, or a change to one that exists? (new / change)\n'
    printf '  5. What does “done” look like, in one sentence?\n'
    printf 'plan: %s\n' "$path"
    if [ -n "$request" ] && [ -n "$who" ] && [ -n "$data" ] && [ -n "$signin" ] && [ -n "$area" ]; then
      _builder_route "$request" "$data" "$signin" "$area"
      printf 'command: %s\n' "$(_builder_command "$request")"
    else
      printf 'command: rorcc workflow new-feature --size <size> --signals <csv> --request "<sentence>"\n'
    fi
    return 0
  fi

  for value in "$request" "$who" "$data" "$signin" "$area" "$done_when"; do
    if [ -n "$value" ] && _builder_secret "$value"; then
      err "that looks like a secret — answer without passwords or tokens"
      return 2
    fi
  done

  if [ -z "$request" ]; then
    if [ ! -t 0 ]; then err "usage: rorcc builder --request <text> (or run in a terminal)"; return 2; fi
    request="$(_builder_ask "What do you want, in one sentence?")" || return 2
  fi
  if [ -z "$who" ]; then
    if [ ! -t 0 ]; then err "pass --who <role> when stdin is not a terminal"; return 2; fi
    who="$(_builder_ask "Who uses this, in one role name?")" || return 2
  fi
  if [ -z "$data" ]; then
    if [ ! -t 0 ]; then err "pass --data yes|no when stdin is not a terminal"; return 2; fi
    data="$(_builder_ask "Does it store or change data? (yes / no)")" || return 2
  fi
  if [ -z "$signin" ]; then
    if [ ! -t 0 ]; then err "pass --sign-in yes|no when stdin is not a terminal"; return 2; fi
    signin="$(_builder_ask "Does it sign someone in or check a permission? (yes / no)")" || return 2
  fi
  if [ -z "$area" ]; then
    if [ ! -t 0 ]; then err "pass --area new|change when stdin is not a terminal"; return 2; fi
    area="$(_builder_ask "New area, or a change to one that exists? (new / change)")" || return 2
  fi
  if [ -z "$done_when" ]; then
    if [ ! -t 0 ]; then err "pass --done <sentence> when stdin is not a terminal"; return 2; fi
    done_when="$(_builder_ask "What does done look like, in one sentence?")" || return 2
  fi

  case "$area" in
    new|nueva) area="new" ;;
    change|cambio|existing) area="change" ;;
    *) err "area must be new or change"; return 2 ;;
  esac
  if ! _builder_yes "$data" && ! printf '%s' "$data" | grep -Eqi '^(n|no)$'; then
    err "data must be yes or no"; return 2
  fi
  if ! _builder_yes "$signin" && ! printf '%s' "$signin" | grep -Eqi '^(n|no)$'; then
    err "sign-in must be yes or no"; return 2
  fi

  _builder_route "$request" "$data" "$signin" "$area"
  _builder_write_plan "$path" "$request" "$who" "$data" "$signin" "$done_when"
  info "plan: $path"
  printf 'command: %s\n' "$(_builder_command "$request")"

  if [ "$accept" -ne 1 ]; then
    if [ ! -t 0 ]; then
      ok "draft saved — rerun with --accept to start the workflow"
      return 0
    fi
    local choice=""
    choice="$(_builder_ask "accept, revise, or quit?")" || return 2
    case "$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')" in
      accept|a|y|yes|sí|si) accept=1 ;;
      quit|q) ok "draft kept at $path"; return 0 ;;
      *) ok "draft kept at $path — run rorcc builder again to revise"; return 0 ;;
    esac
  fi

  local wf_rc=0
  if [ "$BUILDER_SIGNALS" != "none" ]; then
    ( cd "$root" && "$RORCC_HOME/cli/rorcc" workflow new-feature --size "$BUILDER_SIZE" --signals "$BUILDER_SIGNALS" --request "$request" ) || wf_rc=$?
  else
    ( cd "$root" && "$RORCC_HOME/cli/rorcc" workflow new-feature --size "$BUILDER_SIZE" --request "$request" ) || wf_rc=$?
  fi
  [ "$wf_rc" -eq 0 ] || return "$wf_rc"
  "$RORCC_HOME/cli/rorcc" security --size "$BUILDER_SIZE" --signals "$BUILDER_SIGNALS" || return $?
  ok "$done_when"
}
