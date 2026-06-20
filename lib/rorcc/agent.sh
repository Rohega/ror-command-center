# shellcheck shell=bash
# rorcc agent <name> [--local|--cloud] — chat session with an agent.
# Local backend: a compiled Ollama model (rorcc-<name>) via /api/chat.
# Cloud backend: OpenAI/Anthropic with the assembled prompt as the system message.
# Both stream the reply token-by-token.

cmd_agent() {
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
    err "usage: rorcc agent <agent-name> [--local|--cloud]"
    return 2
  fi
  backend="${backend:-${RORCC_BACKEND:-local}}"

  command -v jq >/dev/null 2>&1 || { err "jq is required for 'rorcc agent' (apt install jq | brew install jq)"; return 1; }

  local sysfile="" label
  if [ "$backend" = "cloud" ]; then
    . "$RORCC_LIB_DIR/cloud.sh"
    cloud_check || return 1
    local root; root="$(find_ai_root)" || { err "no .ai/ framework found"; return 1; }
    [ -f "$root/.ai/agents/$name.yaml" ] || { err "agent not found: $name"; return 1; }
    . "$RORCC_LIB_DIR/assemble.sh"
    sysfile="$(mktemp)"
    assemble_system "$root" "$name" > "$sysfile" 2>/dev/null
    apply_context_budget "$sysfile"
    label="cloud:$CLOUD_PROVIDER/$CLOUD_MODEL"
  else
    ollama_running || { err "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"; return 1; }
    if ! ollama_has_model "rorcc-$name"; then
      err "model 'rorcc-$name' not found — build it first: rorcc build-agent $name"
      return 1
    fi
    label="local:rorcc-$name"
  fi

  . "$RORCC_LIB_DIR/chat.sh"
  CHAT_BACKEND="$backend" CHAT_NAME="$name" CHAT_LABEL="$label" \
    CHAT_MODEL="rorcc-$name" CHAT_SYSFILE="$sysfile" CHAT_SEED="" \
    chat_session

  [ -n "$sysfile" ] && rm -f "$sysfile"
}
