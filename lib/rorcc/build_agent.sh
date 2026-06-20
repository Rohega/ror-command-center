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

  # Guard the context budget. Small local models (7-14B) have limited windows;
  # a huge SYSTEM prompt degrades quality. Warn, and optionally hard-cap with
  # RORCC_MAX_CHARS (the prompt is truncated to that many characters).
  local chars; chars="$(wc -c < "$sys" | tr -d ' ')"
  local soft_limit="${RORCC_WARN_CHARS:-32000}"   # ~8k tokens, a safe default
  if [ -n "${RORCC_MAX_CHARS:-}" ] && [ "$chars" -gt "$RORCC_MAX_CHARS" ]; then
    head -c "$RORCC_MAX_CHARS" "$sys" > "$sys.cut" && mv "$sys.cut" "$sys"
    printf '\n[...context truncated to %s chars by RORCC_MAX_CHARS...]\n' "$RORCC_MAX_CHARS" >> "$sys"
    warn "system prompt truncated to $RORCC_MAX_CHARS chars (was $chars)"
    chars="$RORCC_MAX_CHARS"
  elif [ "$chars" -gt "$soft_limit" ]; then
    warn "system prompt is large (${chars} chars) — may exceed small models' context."
    warn "set RORCC_MAX_CHARS=<n> to cap it, or use a larger base model."
  fi

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

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found"; return 1; }

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
