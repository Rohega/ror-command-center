# shellcheck shell=bash
# rorcc skill <name> [--local|--cloud] — run a .ai/skills/<name> skill interactively.
# Loads the skill's responsible agent (from its "## Agent" reference) and layers
# the skill instructions (+ referenced templates) on top, then opens a chat.

cmd_skill() {
  local name="" backend=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --cloud) backend="cloud" ;;
      --local) backend="local" ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) [ -z "$name" ] && name="$1" || { err "unexpected argument: $1"; return 2; } ;;
    esac
    shift
  done
  if [ -z "$name" ]; then
    err "usage: rorcc skill <skill-name> [--local|--cloud]"
    return 2
  fi
  backend="${backend:-${RORCC_BACKEND:-local}}"

  command -v jq >/dev/null 2>&1 || { err "jq is required (apt install jq | brew install jq)"; return 1; }

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found"; return 1; }
  local skill_file="$root/.ai/skills/$name/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    err "skill not found: $name"
    info "available skills:"
    ls "$root/.ai/skills/" | sed 's/^/  - /'
    return 1
  fi

  # Responsible agent: first .ai/agents/<slug>.yaml referenced by the skill.
  local agent_slug
  agent_slug="$(grep -oE '\.ai/agents/[a-z0-9-]+\.yaml' "$skill_file" | head -n1 | sed 's#.*/##; s#\.yaml$##')"

  # Build the skill seed: framing + SKILL.md + any referenced templates.
  local seed; seed="$(mktemp)"
  {
    printf 'You are executing the RoR Command Center skill "%s". Follow its instructions, ask clarifying questions first, present options, and wait for approval before producing final artifacts.\n\n' "$name"
    printf '===== SKILL: %s =====\n' "$name"
    cat "$skill_file"
    local tref tpath
    while IFS= read -r tref; do
      [ -z "$tref" ] && continue
      tpath="$root/$tref"
      [ -f "$tpath" ] && { printf '\n===== TEMPLATE: %s =====\n' "$tref"; cat "$tpath"; }
    done < <(grep -oE '\.ai/templates/[A-Za-z0-9_./-]+' "$skill_file" | sort -u)
  } > "$seed"

  local label sysfile=""
  if [ "$backend" = "cloud" ]; then
    . "$RORCC_LIB_DIR/cloud.sh"
    cloud_check || { rm -f "$seed"; return 1; }
    . "$RORCC_LIB_DIR/assemble.sh"
    sysfile="$(mktemp)"
    [ -n "$agent_slug" ] && [ -f "$root/.ai/agents/$agent_slug.yaml" ] \
      && assemble_system "$root" "$agent_slug" > "$sysfile" 2>/dev/null
    cat "$seed" >> "$sysfile"
    apply_context_budget "$sysfile"
    label="cloud:$CLOUD_PROVIDER/$CLOUD_MODEL · skill:$name"
  else
    ollama_running || { err "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"; rm -f "$seed"; return 1; }
    local model
    if [ -n "$agent_slug" ]; then
      model="rorcc-$agent_slug"
      if ! ollama_has_model "$model"; then
        info "preparing agent '$agent_slug' for this skill..."
        . "$RORCC_LIB_DIR/build_agent.sh"
        cmd_build_agent "$agent_slug" >/dev/null || { err "could not build agent $agent_slug"; rm -f "$seed"; return 1; }
      fi
    else
      model="${RORCC_MODEL:-$RORCC_DEFAULT_MODEL}"
      warn "skill '$name' references no agent — using base model $model"
    fi
    label="local:$model · skill:$name"
  fi

  . "$RORCC_LIB_DIR/chat.sh"
  CHAT_BACKEND="$backend" CHAT_NAME="$name" CHAT_LABEL="$label" \
    CHAT_MODEL="${model:-}" CHAT_SYSFILE="$sysfile" CHAT_SEED="$(cat "$seed")" \
    chat_session

  rm -f "$seed"
  [ -n "$sysfile" ] && rm -f "$sysfile"
}
