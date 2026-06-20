# shellcheck shell=bash
# rorcc workflow <name> [--local|--cloud] — run a .ai/workflows/<name>.yaml end to end.
# Walks each phase in order, runs that phase's skill with its responsible agent
# (injecting phase/gate context), and pauses at each gate for your confirmation.

# _parse_phases <file> → emits one TSV line per phase: label \t agent \t skill \t gate \t notes
_parse_phases() {
  awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function first_in_list(s){ gsub(/^\[|\].*$/,"",s); split(s,a,","); return trim(a[1]) }
    function flush(){ if(have){ printf "%s\t%s\t%s\t%s\t%s\n", label, agent, skill, gate, notes } }
    /^  - id:/      { flush(); have=1; label=""; agent=""; skill=""; gate=""; notes=""; next }
    /^[A-Za-z]/     { flush(); have=0; next }
    have && /^    label:/  { label=trim(substr($0, index($0,":")+1)); next }
    have && /^    agent:/  { agent=trim(substr($0, index($0,":")+1)); next }
    have && /^    agents:/ { agent=first_in_list(trim(substr($0, index($0,":")+1))); next }
    have && /^    skill:/  { skill=trim(substr($0, index($0,":")+1)); next }
    have && /^    skills:/ { skill=first_in_list(trim(substr($0, index($0,":")+1))); next }
    have && /^    gate:/   { gate=trim(substr($0, index($0,":")+1)); next }
    have && /^    notes:/  { notes=trim(substr($0, index($0,":")+1)); next }
    END { flush() }
  ' "$1"
}

cmd_workflow() {
  local name="" backend_flag=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --cloud) backend_flag="--cloud" ;;
      --local) backend_flag="--local" ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) [ -z "$name" ] && name="$1" || { err "unexpected argument: $1"; return 2; } ;;
    esac
    shift
  done
  if [ -z "$name" ]; then
    err "usage: rorcc workflow <workflow-name> [--local|--cloud]"
    return 2
  fi

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found"; return 1; }
  local wf="$root/.ai/workflows/$name.yaml"
  if [ ! -f "$wf" ]; then
    err "workflow not found: $name"
    info "available workflows:"
    ls "$root/.ai/workflows/" | sed 's/\.yaml$//' | sed 's/^/  - /'
    return 1
  fi

  local desc; desc="$(grep -m1 '^description:' "$wf" | sed 's/^description:[[:space:]]*//')"
  info "${C_BOLD}Workflow: $name${C_RESET}"
  [ -n "$desc" ] && printf '  %s\n' "$desc"
  printf '\n'

  # Show the phase plan.
  local n=0 label agent skill gate notes
  while IFS=$'\t' read -r label agent skill gate notes; do
    n=$((n + 1))
    printf '  %b%d)%b %s  %b(%s%s)%b\n' "$C_BLUE" "$n" "$C_RESET" "$label" \
      "$C_DIM" "${agent:-?}" "${skill:+ · $skill}" "$C_RESET"
  done < <(_parse_phases "$wf")
  printf '\n'
  info "Running $n phases. At each phase: [Enter] run · s skip · q quit."
  printf '\n'

  # Run phases in order. Read the phase stream on fd 3 so interactive prompts
  # below can still read the keyboard from stdin.
  local i=0 choice
  while IFS=$'\t' read -r label agent skill gate notes <&3; do
    i=$((i + 1))
    printf '%b\n' "${C_BOLD}── Phase $i/$n: $label ──${C_RESET}"
    [ -n "$agent" ]  && printf '  agent: %s\n' "$agent"
    [ -n "$skill" ]  && printf '  skill: %s\n' "$skill"
    [ -n "$notes" ]  && printf '  notes: %s\n' "$notes"
    [ -n "$gate" ]   && printf '  %bgate:%b  %s\n' "$C_YELLOW" "$C_RESET" "$gate"
    printf '%b' "  [Enter] run · s skip · q quit: "
    IFS= read -r choice || break
    case "$choice" in
      q|Q) info "workflow stopped"; return 0 ;;
      s|S) info "skipped $label"; printf '\n'; continue ;;
    esac

    # Phase context injected into the session.
    export RORCC_SKILL_PREAMBLE="You are working through the '$name' workflow, phase '$label'.${gate:+ Gate to satisfy before completing: $gate.} Apply the workflow design principles (Rails conventions, minimalism, security, tests)."

    if [ -n "$skill" ]; then
      . "$RORCC_LIB_DIR/skill.sh"
      # shellcheck disable=SC2086
      cmd_skill "$skill" $backend_flag
    elif [ -n "$agent" ]; then
      . "$RORCC_LIB_DIR/agent.sh"
      # shellcheck disable=SC2086
      cmd_agent "$agent" $backend_flag
    else
      warn "phase '$label' has no agent or skill — nothing to run"
    fi
    unset RORCC_SKILL_PREAMBLE

    if [ -n "$gate" ]; then
      printf '%b' "  ${C_YELLOW}Gate:${C_RESET} $gate — satisfied? [y/N]: "
      IFS= read -r choice || break
      case "$choice" in
        y|Y|s|S) : ;;
        *) warn "gate not confirmed — pausing workflow at '$label'"; return 0 ;;
      esac
    fi
    printf '\n'
  done 3< <(_parse_phases "$wf")

  ok "workflow '$name' complete"
}
