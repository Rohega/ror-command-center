# shellcheck shell=bash
# Deterministic Smart Router (workflow V3). Selects skills/agents without an LLM.
# See .ai/standards/orchestration.md
#
# Sets:
#   WF_SELECTED  comma-separated units that will run
#   WF_OMITTED   "name:reason,name:reason" for units the router dropped

# Paths listed in a skill's YAML frontmatter (empty if none).
_skill_paths() {
  awk '
    /^---$/ { fm++; next }
    fm==1 && /^paths:[[:space:]]*$/ { p=1; next }
    fm==1 && p && /^  - / {
      line=$0
      sub(/^  - [[:space:]]*/, "", line)
      gsub(/^["'\'']|["'\'']$/, "", line)
      if (line != "") print line
      next
    }
    fm==1 && p && /^[A-Za-z]/ { p=0 }
    fm>=2 { exit }
  ' "$1"
}

# True if $2 (relative glob) matches a file under $1.
_project_has_path() {
  local root="$1" pattern="$2" hit
  pattern="${pattern#./}"
  if [ -z "$pattern" ]; then
    return 1
  fi
  if [[ "$pattern" != *'*'* ]]; then
    [ -e "$root/$pattern" ]
    return $?
  fi
  # find -path: turn ** into * (any depth) and keep single-segment *
  local find_pat="${pattern//\*\*/\*}"
  hit="$(find "$root" -path "$root/$find_pat" -print -quit 2>/dev/null || true)"
  [ -n "$hit" ]
}

_skill_is_contextual() {
  local name="$1" file="$2"
  case "$name" in
    review-*|*-review|*-audit) ;;
    *) return 1 ;;
  esac
  [ -n "$(_skill_paths "$file")" ]
}

_phase_has_producer() {
  local skills="$1" item
  while IFS= read -r item; do
    case "$item" in
      create-*) return 0 ;;
    esac
  done < <(_each_csv "$skills")
  return 1
}

# _route_skills <root> <skills_csv>
# Respects WF_FULL=1 (select all).
_route_skills() {
  local root="$1" skills="$2" item file reason
  WF_SELECTED=""
  WF_OMITTED=""
  while IFS= read -r item; do
    file="$root/.ai/skills/$item/SKILL.md"
    reason=""
    if [ "${WF_FULL:-0}" != "1" ] && _skill_is_contextual "$item" "$file"; then
      if _phase_has_producer "$skills"; then
        :
      else
        local any=0 p
        while IFS= read -r p; do
          if _project_has_path "$root" "$p"; then
            any=1
            break
          fi
        done < <(_skill_paths "$file")
        if [ "$any" -eq 0 ]; then
          reason="no matching paths"
        fi
      fi
    fi
    if [ -n "$reason" ]; then
      WF_OMITTED="${WF_OMITTED:+$WF_OMITTED,}$item:$reason"
    else
      WF_SELECTED="${WF_SELECTED:+$WF_SELECTED,}$item"
    fi
  done < <(_each_csv "$skills")
}

_agent_apply_globs() {
  case "$1" in
    frontend-react-inertia-developer)
      printf '%s\n' app/javascript app/frontend app/assets frontend app/views
      ;;
    *)
      return 1
      ;;
  esac
}

# _route_agents <root> <agents_csv>
_route_agents() {
  local root="$1" agents="$2" item reason p any
  WF_SELECTED=""
  WF_OMITTED=""
  while IFS= read -r item; do
    reason=""
    if [ "${WF_FULL:-0}" != "1" ] && _agent_apply_globs "$item" >/dev/null; then
      any=0
      while IFS= read -r p; do
        if _project_has_path "$root" "$p" || _project_has_path "$root" "$p/**"; then
          any=1
          break
        fi
      done < <(_agent_apply_globs "$item")
      if [ "$any" -eq 0 ]; then
        reason="no frontend tree"
      fi
    fi
    if [ -n "$reason" ]; then
      WF_OMITTED="${WF_OMITTED:+$WF_OMITTED,}$item:$reason"
    else
      WF_SELECTED="${WF_SELECTED:+$WF_SELECTED,}$item"
    fi
  done < <(_each_csv "$agents")
}

# _route_phase <root> <skills_csv> <agents_csv>
# Skills win; agents are routed only when the phase has no skills.
_route_phase() {
  local root="$1" skills="$2" agents="$3"
  if [ -n "$skills" ]; then
    _route_skills "$root" "$skills"
  else
    _route_agents "$root" "$agents"
  fi
}

# True if csv of ids contains $2.
_csv_has() {
  local csv="$1" needle="$2" item
  [ -z "$csv" ] && return 1
  while IFS= read -r item; do
    [ "$item" = "$needle" ] && return 0
  done < <(_each_csv "$csv")
  return 1
}

_all_tokens_are_sizes() {
  local csv="$1" item
  [ -z "$csv" ] && return 1
  while IFS= read -r item; do
    case "$item" in
      S|M|L|XL) ;;
      *) return 1 ;;
    esac
  done < <(_each_csv "$csv")
  return 0
}

_signal_on() {
  case "$1" in
    user_behavior_changed) [ "${WF_SIG_user_behavior_changed:-0}" = "1" ] ;;
    database_changed) [ "${WF_SIG_database_changed:-0}" = "1" ] ;;
    api_changed) [ "${WF_SIG_api_changed:-0}" = "1" ] ;;
    auth_changed) [ "${WF_SIG_auth_changed:-0}" = "1" ] ;;
    architecture_changed) [ "${WF_SIG_architecture_changed:-0}" = "1" ] ;;
    setup_changed) [ "${WF_SIG_setup_changed:-0}" = "1" ] ;;
    infrastructure_changed) [ "${WF_SIG_infrastructure_changed:-0}" = "1" ] ;;
    *) return 1 ;;
  esac
}

_any_signal() {
  local csv="$1" item
  while IFS= read -r item; do
    _signal_on "$item" && return 0
  done < <(_each_csv "$csv")
  return 1
}

_all_signals() {
  local csv="$1" item
  [ -z "$csv" ] && return 1
  while IFS= read -r item; do
    _signal_on "$item" || return 1
  done < <(_each_csv "$csv")
  return 0
}

# One clause: size:L,XL | any:foo,bar | all:foo | L,XL | architecture_changed
_eval_when_clause() {
  local clause="$1"
  clause="${clause#"${clause%%[![:space:]]*}"}"
  clause="${clause%"${clause##*[![:space:]]}"}"
  [ -z "$clause" ] && return 1
  case "$clause" in
    size:*) _csv_has "${clause#size:}" "${WF_SIZE:-}" ;;
    any:*) _any_signal "${clause#any:}" ;;
    all:*) _all_signals "${clause#all:}" ;;
    *)
      if _all_tokens_are_sizes "$clause"; then
        _csv_has "$clause" "${WF_SIZE:-}"
      else
        _any_signal "$clause"
      fi
      ;;
  esac
}

# _applies_when <expr>
# Empty / no classification / --full → true.
# Clauses are OR (split on / ; YAML "|" is normalized to / by the parser).
_applies_when() {
  local expr="${1:-}" rest clause
  [ "${WF_CLASSIFY:-0}" != "1" ] && return 0
  [ "${WF_FULL:-0}" = "1" ] && return 0
  [ -z "$expr" ] && return 0
  rest="$expr"
  while [ -n "$rest" ]; do
    case "$rest" in
      */*) clause="${rest%%/*}"; rest="${rest#*/}" ;;
      *) clause="$rest"; rest="" ;;
    esac
    _eval_when_clause "$clause" && return 0
  done
  return 1
}

# Mark every declared unit omitted with $1. Used when applies_when fails —
# including units the path router already dropped, so the reason stays consistent.
_omit_units() {
  local reason="$1" units="$2" item
  WF_SELECTED=""
  WF_OMITTED=""
  while IFS= read -r item; do
    WF_OMITTED="${WF_OMITTED:+$WF_OMITTED,}$item:$reason"
  done < <(_each_csv "$units")
}
