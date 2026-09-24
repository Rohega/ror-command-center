# shellcheck shell=bash
# rorcc workflow <name> [--plan|--auto|--full|--only ids|--skip ids|--local|--cloud]
# Parser V2 + deterministic V3 router (see .ai/standards/orchestration.md).
# Skills are the execution unit. --plan never calls an LLM.
# shellcheck source=stack.sh
. "$RORCC_LIB_DIR/stack.sh"

# Field separator for parsed phases. Must NOT be IFS whitespace — bash `read`
# collapses consecutive tabs, which would drop empty depends_on/gate/notes.
WF_FS=$'|'
# shellcheck source=router.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/router.sh"
# shellcheck source=classify.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/classify.sh"

# _parse_phases <file>
# PSV: id|label|agents|skills|depends_on|gate|notes|applies_when
# agents/skills/depends_on are comma-separated and preserve every element.
_parse_phases() {
  awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function normalize_list(s,    n,i,a,out) {
      gsub(/^\[|\]$/,"",s)
      n=split(s,a,",")
      out=""
      for(i=1;i<=n;i++){
        a[i]=trim(a[i])
        if(a[i]=="") continue
        out=out (out=="" ? "" : ",") a[i]
      }
      return out
    }
    function append_item(list, item) {
      item=trim(item)
      if(item=="") return list
      if(list=="") return item
      return list "," item
    }
    function value_after_colon(line) {
      return trim(substr(line, index(line,":")+1))
    }
    function clean(s){ gsub(/\|/,"/",s); return s }
    function flush(){
      if(have){
        gsub(/\t/," ",notes)
        printf "%s|%s|%s|%s|%s|%s|%s|%s\n", clean(id), clean(label), clean(agents), clean(skills), clean(depends), clean(gate), clean(notes), clean(applies)
      }
    }
    function stop_collecting(){ collecting=""; collecting_notes=0 }

    /^  - id:/ {
      flush()
      have=1
      stop_collecting()
      id=value_after_colon($0)
      label=""; agents=""; skills=""; depends=""; gate=""; notes=""; applies=""
      next
    }
    /^[A-Za-z]/ { flush(); have=0; stop_collecting(); next }

    have && collecting_notes && /^      / {
      notes=notes (notes=="" ? "" : " ") trim($0)
      next
    }
    have && collecting_notes { collecting_notes=0 }

    have && collecting!="" && /^      - / {
      item=trim(substr($0, index($0,"-")+1))
      if(collecting=="agents")   agents=append_item(agents, item)
      if(collecting=="skills")   skills=append_item(skills, item)
      if(collecting=="depends")  depends=append_item(depends, item)
      next
    }
    have && collecting!="" && ($0 ~ /^    [A-Za-z]/ || $0 ~ /^  - /) {
      collecting=""
    }

    have && /^    label:/  { label=value_after_colon($0); next }
    have && /^    agents:[[:space:]]*$/ { collecting="agents"; next }
    have && /^    agents:/ { agents=append_item(agents, normalize_list(value_after_colon($0))); collecting=""; next }
    have && /^    agent:/  { agents=append_item(agents, value_after_colon($0)); next }
    have && /^    skills:[[:space:]]*$/ { collecting="skills"; next }
    have && /^    skills:/ { skills=append_item(skills, normalize_list(value_after_colon($0))); collecting=""; next }
    have && /^    skill:/  { skills=append_item(skills, value_after_colon($0)); next }
    have && /^    depends_on:[[:space:]]*$/ { collecting="depends"; next }
    have && /^    depends_on:/ { depends=append_item(depends, normalize_list(value_after_colon($0))); collecting=""; next }
    have && /^    gate:/   { gate=value_after_colon($0); next }
    have && /^    applies_when:/ {
      applies=value_after_colon($0)
      applies=normalize_list(applies)
      next
    }
    have && /^    notes:/  {
      notes=value_after_colon($0)
      if(notes==">-" || notes==">" || notes=="|" || notes=="|-"){ notes=""; collecting_notes=1 }
      next
    }
    END { flush() }
  ' "$1"
}

_csv_count() {
  local csv="${1:-}"
  [ -z "$csv" ] && { printf '0\n'; return 0; }
  local IFS=','
  local -a items
  read -r -a items <<< "$csv"
  printf '%s\n' "${#items[@]}"
}

# Emit each comma-separated item on its own line.
_each_csv() {
  local rest="${1:-}" item
  while [ -n "$rest" ]; do
    case "$rest" in
      *,*) item="${rest%%,*}"; rest="${rest#*,}" ;;
      *) item="$rest"; rest="" ;;
    esac
    [ -n "$item" ] && printf '%s\n' "$item"
  done
}

# Declared execution units for one phase: skills, else agents.
_phase_units() {
  local skills="${1:-}" agents="${2:-}"
  if [ -n "$skills" ]; then
    _csv_count "$skills"
  else
    _csv_count "$agents"
  fi
}

_workflow_units() {
  local file="$1" total=0 skills agents
  while IFS="$WF_FS" read -r _id _label agents skills _deps _gate _notes _applies; do
    [ -z "${_id:-}" ] && continue
    total=$((total + $(_phase_units "$skills" "$agents")))
  done < <(_parse_phases "$file")
  printf '%s\n' "$total"
}

_csv_pretty() {
  local csv="${1:-}"
  [ -z "$csv" ] && { printf 'none\n'; return 0; }
  printf '%s\n' "${csv//,/, }"
}

# Unknown agent-like names in a skill ## Agent section (stale roster ids).
_skill_stale_agent_refs() {
  local skill_file="$1" root="$2" slug
  [ -f "$skill_file" ] || return 0
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    [ -f "$root/.ai/agents/$slug.yaml" ] && continue
    [ -d "$root/.ai/skills/$slug" ] && continue
    printf '%s\n' "$slug"
  done < <(
    grep -oE '\.ai/agents/[a-z0-9-]+\.yaml' "$skill_file" 2>/dev/null \
      | sed 's#.*/##; s#\.yaml$##'
    awk '/^## Agent/{p=1;next} p&&/^## /{exit} p' "$skill_file" \
      | grep -oE '`[a-z0-9-]+`' | tr -d '`'
  )
}

# _dep_outcome <depends_csv> <state_file> → passed | blocked
# A phase may run only when every dependency is passed.
# skipped / blocked / failed / pending / missing → blocked.
_dep_outcome() {
  local deps="${1:-}" state="$2" dep st
  [ -z "$deps" ] && { printf 'passed\n'; return 0; }
  [ ! -f "$state" ] && { printf 'blocked\n'; return 0; }
  while IFS= read -r dep; do
    # --only: dependencies outside the requested set are assumed already done.
    if [ -n "${WF_ONLY:-}" ] && ! _csv_has "$WF_ONLY" "$dep"; then
      continue
    fi
    st="$(awk -F'\t' -v id="$dep" 'NR>1 && $1==id {print $2; exit}' "$state")"
    if [ "$st" != "passed" ]; then
      printf 'blocked\n'
      return 0
    fi
  done < <(_each_csv "$deps")
  printf 'passed\n'
}

_state_set() {
  local file="$1" id="$2" status="$3" tmp
  tmp="$(mktemp)"
  if [ -f "$file" ]; then
    awk -F'\t' -v id="$id" -v st="$status" 'BEGIN{OFS="\t"} NR==1{print; next} $1==id{$2=st} {print}' "$file" > "$tmp"
    if ! awk -F'\t' -v id="$id" 'NR>1 && $1==id {found=1} END{exit !found}' "$tmp"; then
      printf '%s\t%s\n' "$id" "$status" >> "$tmp"
    fi
  else
    printf 'phase_id\tstatus\n%s\t%s\n' "$id" "$status" > "$tmp"
  fi
  mv "$tmp" "$file"
}

# _preflight_workflow <yaml> <root>
# Prints "workflow invalid" + reasons on failure. No LLM.
_preflight_workflow() {
  local wf="$1" root="$2"
  local invalid=0
  local id label agents skills deps gate notes applies
  local seen_ids="" seen
  local item stale

  while IFS="$WF_FS" read -r id label agents skills deps gate notes applies; do
    [ -z "$id" ] && continue

    case " $seen_ids " in
      *" $id "*) err "duplicate phase id: $id"; invalid=1 ;;
      *) seen_ids="$seen_ids $id" ;;
    esac

    while IFS= read -r item; do
      if [ "$item" = "$id" ]; then
        err "phase '$id' depends on itself"
        invalid=1
      fi
    done < <(_each_csv "$deps")

    while IFS= read -r item; do
      if [ ! -f "$root/.ai/agents/$item.yaml" ]; then
        err "agent not found: $item"
        invalid=1
      fi
    done < <(_each_csv "$agents")

    while IFS= read -r item; do
      if [ ! -f "$root/.ai/skills/$item/SKILL.md" ]; then
        err "skill not found: $item"
        invalid=1
        continue
      fi
      while IFS= read -r stale; do
        [ -z "$stale" ] && continue
        err "skill '$item' references unknown agent: $stale"
        invalid=1
      done < <(_skill_stale_agent_refs "$root/.ai/skills/$item/SKILL.md" "$root")
    done < <(_each_csv "$skills")
  done < <(_parse_phases "$wf")

  # Second pass: depends_on targets must exist (needs the full id set).
  while IFS="$WF_FS" read -r id label agents skills deps gate notes applies; do
    [ -z "$id" ] && continue
    while IFS= read -r item; do
      seen=0
      case " $seen_ids " in
        *" $item "*) seen=1 ;;
      esac
      if [ "$seen" -eq 0 ]; then
        err "depends_on '$item' on phase '$id' does not exist"
        invalid=1
      fi
    done < <(_each_csv "$deps")
  done < <(_parse_phases "$wf")

  if [ "$invalid" -ne 0 ]; then
    err "workflow invalid"
    return 1
  fi
  return 0
}

_print_workflow_plan() {
  local name="$1" wf="$2" root="$3"
  local i=0 id label agents skills deps gate notes applies
  local declared=0 selected=0 omitted=0
  local scope_note=""

  printf '%s\n' "Workflow: $name"
  printf 'stack: %s\n' "$(_stack_id "$root")"
  if [ "${WF_CLASSIFY:-0}" = "1" ]; then
    printf '\n'
    printf '%s\n' "Classification:"
    _classify_format | sed 's/^/  /'
  fi
  printf '\n'

  while IFS="$WF_FS" read -r id label agents skills deps gate notes applies; do
    [ -z "$id" ] && continue
    i=$((i + 1))
    declared=$((declared + $(_phase_units "$skills" "$agents")))
    scope_note=""
    if [ -n "${WF_ONLY:-}" ] && ! _csv_has "$WF_ONLY" "$id"; then
      scope_note="out of --only"
    elif [ -n "${WF_SKIP:-}" ] && _csv_has "$WF_SKIP" "$id"; then
      scope_note="--skip"
    elif [ "${WF_CLASSIFY:-0}" = "1" ] && [ "${WF_FULL:-0}" != "1" ] \
      && { [ -z "${WF_ONLY:-}" ] || ! _csv_has "$WF_ONLY" "$id"; } \
      && ! _applies_when "$applies"; then
      scope_note="applies_when"
    fi

    _route_phase "$root" "$skills" "$agents"
    if [ "$scope_note" = "applies_when" ]; then
      _omit_units "applies_when" "${skills:-$agents}"
    fi
    if [ -n "$scope_note" ]; then
      omitted=$((omitted + $(_phase_units "$skills" "$agents")))
    else
      selected=$((selected + $(_csv_count "${WF_SELECTED:-}")))
      omitted=$((omitted + $(_csv_count "${WF_OMITTED:-}")))
    fi

    printf '%d. %s\n' "$i" "${label:-$id}"
    printf '   id: %s\n' "$id"
    if [ -n "$scope_note" ]; then
      printf '   selected: none (%s)\n' "$scope_note"
    elif [ -n "$WF_SELECTED" ]; then
      printf '   selected: %s\n' "$(_csv_pretty "$WF_SELECTED")"
    else
      printf '   selected: none\n'
    fi
    if [ -n "$WF_OMITTED" ] && { [ -z "$scope_note" ] || [ "$scope_note" = "applies_when" ]; }; then
      printf '   omitted: %s\n' "$(_csv_pretty "$WF_OMITTED")"
    fi
    [ -n "$skills" ] && [ -n "$agents" ] && printf '   agents: %s\n' "$(_csv_pretty "$agents")"
    printf '   dependencies: %s\n' "$(_csv_pretty "$deps")"
    [ -n "$gate" ] && printf '   gate: %s\n' "$gate"
    printf '\n'
  done < <(_parse_phases "$wf")

  printf 'Declared units: %s\n' "$declared"
  printf 'Selected units: %s\n' "$selected"
  printf 'Omitted units: %s\n' "$omitted"
  printf 'Execution units: %s\n' "$selected"
  printf 'LLM calls performed: 0\n'
}

_write_summary() {
  local file="$1" workflow="$2" run_id="$3" state="$4" units="$5" elapsed="$6"
  local total=0 passed=0 skipped=0 blocked=0 failed=0
  local st
  if [ -f "$state" ]; then
    while IFS=$'\t' read -r _id st; do
      [ "$_id" = "phase_id" ] && continue
      [ -z "${_id:-}" ] && continue
      total=$((total + 1))
      case "$st" in
        passed)  passed=$((passed + 1)) ;;
        skipped) skipped=$((skipped + 1)) ;;
        blocked) blocked=$((blocked + 1)) ;;
        failed)  failed=$((failed + 1)) ;;
      esac
    done < "$state"
  fi
  {
    printf 'workflow\trun_id\tphases_total\tphases_passed\tphases_skipped\tphases_blocked\tphases_failed\texecution_units\telapsed_seconds\n'
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$workflow" "$run_id" "$total" "$passed" "$skipped" "$blocked" "$failed" "$units" "$elapsed"
  } > "$file"
}

_run_csv_items() {
  # $1=kind (skill|agent) $2=csv $3=backend_flag
  local kind="$1" csv="$2" backend_flag="$3" item rc=0
  while IFS= read -r item; do
    if [ "$kind" = "skill" ]; then
      # shellcheck source=skill.sh disable=SC1091
      . "$RORCC_LIB_DIR/skill.sh"
      # shellcheck disable=SC2086
      cmd_skill "$item" $backend_flag || rc=1
    else
      # shellcheck source=agent.sh disable=SC1091
      . "$RORCC_LIB_DIR/agent.sh"
      # shellcheck disable=SC2086
      cmd_agent "$item" $backend_flag || rc=1
    fi
    [ "$rc" -ne 0 ] && return 1
  done < <(_each_csv "$csv")
  return 0
}

_workflow_classify() {
  WF_CLASSIFY=0
  unset WF_SIZE WF_CLASS_REASON
  _classify_reset
  if [ -z "${WF_REQUEST:-}" ] && [ -z "${WF_SIZE_OVERRIDE:-}" ] && [ -z "${WF_SIGNALS_OVERRIDE:-}" ]; then
    export WF_CLASSIFY=0
    return 0
  fi
  WF_CLASSIFY=1
  if [ -n "${WF_REQUEST:-}" ]; then
    _classify_request "$WF_REQUEST"
  fi
  if [ -n "${WF_SIZE_OVERRIDE:-}" ]; then
    WF_SIZE="$WF_SIZE_OVERRIDE"
    [ -z "${WF_CLASS_REASON:-}" ] && WF_CLASS_REASON="Size set with --size."
  fi
  if [ -n "${WF_SIGNALS_OVERRIDE:-}" ]; then
    _classify_reset_signals
    _classify_apply_signals "$WF_SIGNALS_OVERRIDE" || return $?
    [ -z "${WF_SIZE:-}" ] && WF_SIZE=M
    [ -z "${WF_CLASS_REASON:-}" ] && WF_CLASS_REASON="Signals set with --signals."
  fi
  export WF_CLASSIFY WF_SIZE WF_CLASS_REASON
  export WF_SIG_user_behavior_changed WF_SIG_database_changed WF_SIG_api_changed
  export WF_SIG_auth_changed WF_SIG_architecture_changed WF_SIG_setup_changed
  export WF_SIG_infrastructure_changed
}

cmd_workflow() {
  local name="" backend_flag="" plan=0 auto=0
  WF_ONLY=""; WF_SKIP=""; export WF_FULL=0
  WF_REQUEST=""; WF_SIZE_OVERRIDE=""; WF_SIGNALS_OVERRIDE=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --plan)  plan=1 ;;
      --auto)  auto=1 ;;
      --full)  WF_FULL=1; export WF_FULL ;;
      --only)
        shift
        [ -n "${1:-}" ] || { err "usage: --only <id,id>"; return 2; }
        WF_ONLY="$1"
        ;;
      --skip)
        shift
        [ -n "${1:-}" ] || { err "usage: --skip <id,id>"; return 2; }
        WF_SKIP="$1"
        ;;
      --request)
        shift
        [ -n "${1:-}" ] || { err "usage: --request <text>"; return 2; }
        WF_REQUEST="$1"
        ;;
      --size)
        shift
        case "${1:-}" in
          S|M|L|XL) WF_SIZE_OVERRIDE="$1" ;;
          *) err "usage: --size S|M|L|XL"; return 2 ;;
        esac
        ;;
      --signals)
        shift
        [ -n "${1:-}" ] || { err "usage: --signals <name,name>"; return 2; }
        WF_SIGNALS_OVERRIDE="$1"
        ;;
      --cloud) backend_flag="--cloud" ;;
      --local) backend_flag="--local" ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) [ -z "$name" ] && name="$1" || { err "unexpected argument: $1"; return 2; } ;;
    esac
    shift
  done
  if [ -z "$name" ]; then
    err "usage: rorcc workflow <workflow-name> [--plan|--auto|--full|--only ids|--skip ids|--request text|--size S|M|L|XL|--signals names|--local|--cloud]"
    return 2
  fi
  if ! _workflow_classify; then
    return 2
  fi

  local root; root="$(require_ai_root)" || return 1
  local wf="$root/.ai/workflows/$name.yaml"
  if [ ! -f "$wf" ]; then
    err "workflow not found: $name"
    info "available workflows:"
    ls "$root/.ai/workflows/" | sed 's/\.yaml$//' | sed 's/^/  - /'
    return 1
  fi

  if ! _preflight_workflow "$wf" "$root"; then
    return 1
  fi

  export RORCC_LEAN=1
  if [ "$auto" -eq 1 ]; then
    export RORCC_WORKFLOW_AUTO=1
  else
    unset RORCC_WORKFLOW_AUTO
  fi

  if [ "$plan" -eq 1 ]; then
    _print_workflow_plan "$name" "$wf" "$root"
    return 0
  fi

  local desc; desc="$(grep -m1 '^description:' "$wf" | sed 's/^description:[[:space:]]*//')"
  info "${C_BOLD}Workflow: $name${C_RESET}"
  [ -n "$desc" ] && printf '  %s\n' "$desc"
  if [ "${WF_CLASSIFY:-0}" = "1" ]; then
    printf '  classification: size=%s\n' "${WF_SIZE:-?}"
  fi
  printf '\n'

  local n=0 id label agents skills deps gate notes applies units
  while IFS="$WF_FS" read -r id label agents skills deps gate notes applies; do
    [ -z "$id" ] && continue
    n=$((n + 1))
    units="$(_phase_units "$skills" "$agents")"
    printf '  %b%d)%b %s  %b(%s · %s units)%b\n' "$C_BLUE" "$n" "$C_RESET" \
      "${label:-$id}" "$C_DIM" "${skills:-${agents:-?}}" "$units" "$C_RESET"
  done < <(_parse_phases "$wf")
  printf '\n'
  info "Running $n phases. Router selects skills; agents run only when a phase has no skills."
  if [ "$auto" -eq 1 ]; then
    info "--auto: one-shot per unit; gates still need confirmation."
  else
    info "At each phase: [Enter] run · s skip · q quit."
  fi
  printf '\n'

  local run_id run_dir state_file metrics_file summary_file
  run_id="$(date +%Y%m%dT%H%M%S)-$$"
  run_dir="$root/.rorcc/runs/$run_id"
  mkdir -p "$run_dir"
  state_file="$run_dir/state.tsv"
  metrics_file="$run_dir/metrics.tsv"
  summary_file="$run_dir/summary.tsv"
  printf 'phase_id\tstatus\n' > "$state_file"
  printf 'phase_id\telapsed_seconds\texecution_units\tstatus\n' > "$metrics_file"
  while IFS="$WF_FS" read -r id _r _a _s _d _g _n; do
    [ -z "$id" ] && continue
    printf '%s\tpending\n' "$id" >> "$state_file"
  done < <(_parse_phases "$wf")

  local i=0 choice run_start now elapsed rc units_run total_units=0
  local any_failed=0 any_blocked=0
  run_start="$(date +%s)"

  while IFS="$WF_FS" read -r id label agents skills deps gate notes applies <&3; do
    [ -z "$id" ] && continue
    i=$((i + 1))
    units="$(_phase_units "$skills" "$agents")"
    _route_phase "$root" "$skills" "$agents"
    if [ "${WF_CLASSIFY:-0}" = "1" ] && [ "${WF_FULL:-0}" != "1" ] \
      && { [ -z "${WF_ONLY:-}" ] || ! _csv_has "$WF_ONLY" "$id"; } \
      && ! _applies_when "$applies"; then
      _omit_units "applies_when" "${skills:-$agents}"
    fi
    printf '%b\n' "${C_BOLD}── Phase $i/$n: ${label:-$id} ──${C_RESET}"
    [ -n "$agents" ] && printf '  agents: %s\n' "$(_csv_pretty "$agents")"
    if [ -n "$skills" ]; then
      printf '  declared: %s\n' "$(_csv_pretty "$skills")"
    fi
    printf '  selected: %s\n' "$(_csv_pretty "${WF_SELECTED:-}")"
    [ -n "$WF_OMITTED" ] && printf '  omitted: %s\n' "$(_csv_pretty "$WF_OMITTED")"
    [ -n "$deps" ]  && printf '  depends_on: %s\n' "$(_csv_pretty "$deps")"
    [ -n "$notes" ] && printf '  notes: %s\n' "$notes"
    [ -n "$gate" ]  && printf '  %bgate:%b  %s\n' "$C_YELLOW" "$C_RESET" "$gate"

    if [ -n "${WF_ONLY:-}" ] && ! _csv_has "$WF_ONLY" "$id"; then
      info "skipped $id (not in --only)"
      _state_set "$state_file" "$id" "skipped"
      printf '%s\t%s\t%s\t%s\n' "$id" "0" "0" "skipped" >> "$metrics_file"
      printf '\n'
      continue
    fi
    if [ -n "${WF_SKIP:-}" ] && _csv_has "$WF_SKIP" "$id"; then
      info "skipped $id (--skip)"
      _state_set "$state_file" "$id" "skipped"
      printf '%s\t%s\t%s\t%s\n' "$id" "0" "0" "skipped" >> "$metrics_file"
      printf '\n'
      continue
    fi
    if [ "${WF_CLASSIFY:-0}" = "1" ] && [ "${WF_FULL:-0}" != "1" ] \
      && { [ -z "${WF_ONLY:-}" ] || ! _csv_has "$WF_ONLY" "$id"; } \
      && ! _applies_when "$applies"; then
      info "phase '$id' omitted by applies_when — passing"
      _state_set "$state_file" "$id" "passed"
      printf '%s\t%s\t%s\t%s\n' "$id" "0" "0" "passed" >> "$metrics_file"
      printf '\n'
      continue
    fi

    if [ "$(_dep_outcome "$deps" "$state_file")" = "blocked" ]; then
      warn "phase '$id' blocked — dependencies are not all passed"
      _state_set "$state_file" "$id" "blocked"
      printf '%s\t%s\t%s\t%s\n' "$id" "0" "$units" "blocked" >> "$metrics_file"
      any_blocked=1
      printf '\n'
      continue
    fi

    if [ "$auto" -eq 0 ]; then
      printf '%b' "  [Enter] run · s skip · q quit: "
      IFS= read -r choice || break
      case "$choice" in
        q|Q)
          info "workflow stopped"
          now="$(date +%s)"
          _write_summary "$summary_file" "$name" "$run_id" "$state_file" "$total_units" "$((now - run_start))"
          return 0
          ;;
        s|S)
          info "skipped $label"
          _state_set "$state_file" "$id" "skipped"
          printf '%s\t%s\t%s\t%s\n' "$id" "0" "$units" "skipped" >> "$metrics_file"
          printf '\n'
          continue
          ;;
      esac
    fi

    _state_set "$state_file" "$id" "running"
    export RORCC_SKILL_PREAMBLE="You are working through the '$name' workflow, phase '${label:-$id}'.${gate:+ Gate to satisfy before completing: $gate.} Apply the workflow design principles (Rails conventions, minimalism, security, tests)."

    now="$(date +%s)"
    rc=0
    units_run=0
    if [ -z "${WF_SELECTED:-}" ]; then
      info "phase '$id' has no applicable units — passing"
      units_run=0
    elif [ -n "$skills" ]; then
      _run_csv_items skill "$WF_SELECTED" "$backend_flag" || rc=1
      units_run="$(_csv_count "$WF_SELECTED")"
    else
      _run_csv_items agent "$WF_SELECTED" "$backend_flag" || rc=1
      units_run="$(_csv_count "$WF_SELECTED")"
    fi
    unset RORCC_SKILL_PREAMBLE
    elapsed=$(( $(date +%s) - now ))

    if [ "$rc" -ne 0 ]; then
      _state_set "$state_file" "$id" "failed"
      printf '%s\t%s\t%s\t%s\n' "$id" "$elapsed" "$units_run" "failed" >> "$metrics_file"
      any_failed=1
      warn "phase '$id' failed"
      printf '\n'
      continue
    fi

    if [ -n "$gate" ]; then
      printf '%b' "  ${C_YELLOW}Gate:${C_RESET} $gate — satisfied? [y/N]: "
      IFS= read -r choice || break
      case "$choice" in
        y|Y|s|S) : ;;
        *)
          warn "gate not confirmed — pausing workflow at '${label:-$id}'"
          _state_set "$state_file" "$id" "failed"
          printf '%s\t%s\t%s\t%s\n' "$id" "$elapsed" "$units_run" "failed" >> "$metrics_file"
          now="$(date +%s)"
          _write_summary "$summary_file" "$name" "$run_id" "$state_file" "$((total_units + units_run))" "$((now - run_start))"
          return 0
          ;;
      esac
    fi

    _state_set "$state_file" "$id" "passed"
    printf '%s\t%s\t%s\t%s\n' "$id" "$elapsed" "$units_run" "passed" >> "$metrics_file"
    total_units=$((total_units + units_run))
    printf '\n'
  done 3< <(_parse_phases "$wf")

  now="$(date +%s)"
  _write_summary "$summary_file" "$name" "$run_id" "$state_file" "$total_units" "$((now - run_start))"
  info "run state: $run_dir"

  if [ "$any_failed" -ne 0 ] || [ "$any_blocked" -ne 0 ]; then
    warn "workflow '$name' finished with blocked or failed phases"
    return 1
  fi
  ok "workflow '$name' complete"
}
