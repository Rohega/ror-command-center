# shellcheck shell=bash
# rorcc agent <name> — local chat session with a compiled agent, backed by Ollama.
# Talks to the Ollama REST API (/api/chat) over curl, keeping conversation history.

cmd_agent() {
  local name="${1:-}"
  if [ -z "$name" ]; then
    err "usage: rorcc agent <agent-name>   (e.g. rails-architect)"
    return 2
  fi

  command -v jq >/dev/null 2>&1 || { err "jq is required for 'rorcc agent' (apt install jq | brew install jq)"; return 1; }
  ollama_running || { err "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"; return 1; }

  local model="rorcc-$name"
  if ! ollama_has_model "$model"; then
    err "model '$model' not found — build it first: rorcc build-agent $name"
    return 1
  fi

  info "Chatting with ${C_BOLD}$name${C_RESET} (model: $model). Type ${C_DIM}/exit${C_RESET} to quit, ${C_DIM}/reset${C_RESET} to clear history."
  printf '\n'

  local messages='[]'
  local input content payload resp

  while true; do
    printf '%b' "${C_GREEN}you ›${C_RESET} "
    IFS= read -r input || break
    case "$input" in
      "")        continue ;;
      "/exit"|"/quit") break ;;
      "/reset")  messages='[]'; info "history cleared"; continue ;;
    esac

    messages="$(jq --arg c "$input" '. += [{"role":"user","content":$c}]' <<<"$messages")"
    payload="$(jq -n --arg m "$model" --argjson msgs "$messages" '{model:$m, messages:$msgs, stream:false}')"

    resp="$(curl -fsS "$OLLAMA_HOST/api/chat" -d "$payload" 2>/dev/null)" || {
      err "request to Ollama failed"; continue
    }
    content="$(jq -r '.message.content // empty' <<<"$resp")"
    if [ -z "$content" ]; then
      err "empty response (model error: $(jq -r '.error // "unknown"' <<<"$resp"))"
      continue
    fi

    printf '%b\n%s\n\n' "${C_BLUE}$name ›${C_RESET}" "$content"
    messages="$(jq --arg c "$content" '. += [{"role":"assistant","content":$c}]' <<<"$messages")"
  done

  printf '\n'
  info "session ended"
}
