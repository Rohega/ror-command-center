# shellcheck shell=bash
# rorcc — shared system-prompt assembly.
# Builds the agent system prompt from .ai/agents/<name>.yaml plus every
# .ai/ path it references. Used by build-agent (Ollama Modelfile) and by the
# cloud backend (sent as the system message). Writes the prompt to stdout.

# assemble_system <root> <name>  → prints the assembled system prompt
# Side effect: prints "inlined N standard(s)" to stderr.
assemble_system() {
  local root="$1" name="$2"
  local agent_file="$root/.ai/agents/$name.yaml"

  printf 'You are the "%s" specialist of RoR Command Center, a production-grade Ruby on Rails AI engineering team.\n' "$name"
  printf 'Follow the role definition and engineering standards below. Stay in character, ask clarifying questions, present options, and never invent files without approval.\n\n'
  printf '===== ROLE DEFINITION (%s.yaml) =====\n' "$name"
  cat "$agent_file"
  printf '\n'

  local ref count=0 ref_path
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    ref_path="$root/$ref"
    if [ -f "$ref_path" ]; then
      printf '\n===== STANDARD: %s =====\n' "$ref"
      cat "$ref_path"
      count=$((count + 1))
    fi
  done < <(grep -oE '\.ai/[A-Za-z0-9_./-]+' "$agent_file" | sort -u)
  printf 'inlined %s referenced standard(s)\n' "$count" >&2
}

# Lean workflow prompt: specialist purpose only (no inlined standards dump).
# Skills already name the standards that apply.
assemble_lean() {
  local root="$1" name="$2"
  local agent_file="$root/.ai/agents/$name.yaml"
  local purpose=""
  if [ -f "$agent_file" ]; then
    purpose="$(grep -m1 '^purpose:' "$agent_file" | sed 's/^purpose:[[:space:]]*//')"
  fi
  printf 'You are the "%s" specialist of RoR Command Center.\n' "$name"
  [ -n "$purpose" ] && printf '%s\n' "$purpose"
  printf 'Follow the attached skill. Standards the skill names still apply; do not request a full standards dump.\n'
}

# apply_context_budget <file>  → trims/warns based on RORCC_MAX_CHARS / RORCC_WARN_CHARS
apply_context_budget() {
  local f="$1"
  local chars; chars="$(wc -c < "$f" | tr -d ' ')"
  local soft_limit="${RORCC_WARN_CHARS:-32000}"
  if [ -n "${RORCC_MAX_CHARS:-}" ] && [ "$chars" -gt "$RORCC_MAX_CHARS" ]; then
    head -c "$RORCC_MAX_CHARS" "$f" > "$f.cut" && mv "$f.cut" "$f"
    printf '\n[...context truncated to %s chars by RORCC_MAX_CHARS...]\n' "$RORCC_MAX_CHARS" >> "$f"
    warn "system prompt truncated to $RORCC_MAX_CHARS chars (was $chars)"
  elif [ "$chars" -gt "$soft_limit" ]; then
    warn "system prompt is large (${chars} chars) — may exceed small models' context."
    warn "set RORCC_MAX_CHARS=<n> to cap it, or use a larger base model."
  fi
}
