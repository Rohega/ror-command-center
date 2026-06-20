# shellcheck shell=bash
# rorcc build-agent <name> — compile a .ai/agents/<name>.yaml (+ its referenced
# standards) into an Ollama Modelfile and register it as "rorcc-<name>".

cmd_build_agent() {
  local name="${1:-}"
  if [ -z "$name" ]; then
    err "usage: rorcc build-agent <agent-name>   (e.g. rails-architect)"
    return 2
  fi

  local root
  root="$(find_ai_root)" || { err "no .ai/ framework found"; return 1; }

  local agent_file="$root/.ai/agents/$name.yaml"
  if [ ! -f "$agent_file" ]; then
    err "agent not found: $agent_file"
    info "available agents:"
    ls "$root/.ai/agents/" | sed 's/\.yaml$//' | sed 's/^/  - /'
    return 1
  fi

  local base_model="${RORCC_MODEL:-$RORCC_DEFAULT_MODEL}"
  local build_dir="$root/.rorcc/build/$name"
  local modelfile="$build_dir/Modelfile"
  mkdir -p "$build_dir"

  info "Building agent '${C_BOLD}$name${C_RESET}' on base model ${C_DIM}$base_model${C_RESET}"

  # Assemble the SYSTEM prompt into a temp file (avoids arg-length limits).
  local sys="$build_dir/system.txt"
  {
    printf 'You are the "%s" specialist of RoR Command Center, a production-grade Ruby on Rails AI engineering team.\n' "$name"
    printf 'Follow the role definition and engineering standards below. Stay in character, ask clarifying questions, present options, and never invent files without approval.\n\n'
    printf '===== ROLE DEFINITION (%s.yaml) =====\n' "$name"
    cat "$agent_file"
    printf '\n'

    # Pull every .ai/... path referenced by the agent and inline it.
    local ref count=0
    while IFS= read -r ref; do
      [ -z "$ref" ] && continue
      local ref_path="$root/$ref"
      if [ -f "$ref_path" ]; then
        printf '\n===== STANDARD: %s =====\n' "$ref"
        cat "$ref_path"
        count=$((count + 1))
      fi
    done < <(grep -oE '\.ai/[A-Za-z0-9_./-]+' "$agent_file" | sort -u)
    printf '\n' >&2
    info "inlined $count referenced standard(s)" >&2
  } > "$sys"

  # Write the Modelfile. Ollama reads SYSTEM as a quoted block.
  {
    printf 'FROM %s\n' "$base_model"
    printf 'PARAMETER temperature 0.2\n'
    printf 'SYSTEM """\n'
    cat "$sys"
    printf '\n"""\n'
  } > "$modelfile"

  ok "Modelfile written: ${C_DIM}$modelfile${C_RESET}"

  if ! ollama_installed; then
    warn "ollama not installed — Modelfile generated but not registered."
    warn "Install Ollama, then run: ollama create rorcc-$name -f \"$modelfile\""
    return 0
  fi
  if ! ollama_running; then
    warn "ollama daemon not running — start it ('ollama serve'), then run:"
    warn "  ollama create rorcc-$name -f \"$modelfile\""
    return 0
  fi

  info "Registering model 'rorcc-$name' with Ollama..."
  if ollama create "rorcc-$name" -f "$modelfile"; then
    ok "agent ready — run it with: rorcc agent $name"
  else
    err "ollama create failed (is the base model '$base_model' pulled? try: ollama pull $base_model)"
    return 1
  fi
}
