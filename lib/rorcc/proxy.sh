# shellcheck shell=bash
# rorcc proxy — bridge local Ollama to IDE AI clients (Cursor, Claude Code).
# Prints copy-paste config; with --start, launches a LiteLLM gateway that exposes
# OpenAI- and Anthropic-compatible endpoints in front of Ollama. Best-effort:
# client behavior changes between versions.

cmd_proxy() {
  local start=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --start) start=1 ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) err "unexpected argument: $1"; return 2 ;;
    esac
    shift
  done

  local model="${RORCC_MODEL:-$RORCC_DEFAULT_MODEL}"
  local port="${RORCC_PROXY_PORT:-4000}"

  info "${C_BOLD}Use local Ollama from your IDE${C_RESET}"
  printf '\n'

  printf '%b\n' "${C_BOLD}Cursor${C_RESET} (OpenAI-compatible, no proxy needed):"
  cat <<EOF
  Settings → Models → add a custom OpenAI model:
    • Base URL:  $OLLAMA_HOST/v1
    • API key:   ollama   (any non-empty string)
    • Model:     $model
  Note: Cursor may try to verify the endpoint from its servers; a purely local
  URL can fail verification depending on the version (best-effort).

EOF

  printf '%b\n' "${C_BOLD}Claude Code${C_RESET} (needs an Anthropic-compatible gateway):"
  cat <<EOF
  Claude Code speaks the Anthropic API, so run a LiteLLM gateway in front of Ollama:
    pip install litellm
    rorcc proxy --start
  Then point Claude Code at it:
    export ANTHROPIC_BASE_URL=http://localhost:$port
    export ANTHROPIC_API_KEY=sk-anything
EOF
  printf '\n'

  if [ "$start" -ne 1 ]; then
    info "run ${C_DIM}rorcc proxy --start${C_RESET} to launch the LiteLLM gateway on port $port"
    return 0
  fi

  if ! command -v litellm >/dev/null 2>&1; then
    err "litellm not installed — run: pip install litellm"
    return 1
  fi
  ollama_running || warn "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"

  info "starting LiteLLM gateway for ${C_BOLD}ollama/$model${C_RESET} on port $port (Ctrl-C to stop)..."
  exec litellm --model "ollama/$model" --port "$port"
}
