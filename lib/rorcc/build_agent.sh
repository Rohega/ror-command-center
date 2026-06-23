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
  root="$(require_ai_root)" || return 1

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

  # Assemble the SYSTEM prompt into a file (shared with the cloud backend).
  . "$RORCC_LIB_DIR/assemble.sh"
  local sys="$build_dir/system.txt"
  assemble_system "$root" "$name" > "$sys"
  apply_context_budget "$sys"

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

# rorcc update [name] — recompile agents after editing .ai/.
# With a name: rebuild that one. Without: rebuild every already-compiled agent
# (rorcc-* models), or all .ai/agents if none are compiled yet.
cmd_update() {
  local name="${1:-}"
  if [ -n "$name" ]; then
    cmd_build_agent "$name"
    return $?
  fi

  ollama_running || { err "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"; return 1; }

  local root; root="$(require_ai_root)" || return 1

  local slugs
  slugs="$(ollama list 2>/dev/null | awk '$1 ~ /^rorcc-/ {print $1}' | sed 's/^rorcc-//')"
  if [ -z "$slugs" ]; then
    info "no compiled agents found — building all from .ai/agents/"
    slugs="$(ls "$root/.ai/agents/" | sed 's/\.yaml$//')"
  fi

  local s rc=0
  for s in $slugs; do
    cmd_build_agent "$s" || rc=1
  done
  return "$rc"
}
