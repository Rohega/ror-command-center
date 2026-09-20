# shellcheck shell=bash
# rorcc — shared interactive chat loop (used by 'agent' and 'skill').
# Streams replies token-by-token from the local Ollama model or the cloud backend.
#
# Caller sets:
#   CHAT_BACKEND   local|cloud
#   CHAT_NAME      display name
#   CHAT_LABEL     short backend label for the header
#   CHAT_MODEL     (local) Ollama model, e.g. rorcc-rails-architect
#   CHAT_SYSFILE   (cloud) assembled system-prompt file
#   CHAT_SEED      (optional, local only) extra system message prepended once
#   CHAT_ONCE      if 1, send one user turn (CHAT_USER or a default) and exit
#   CHAT_USER      (optional) the one-shot user message

# Lightweight "thinking" hint: model load + prompt eval can take seconds before
# the first token, which looks frozen. Show a hint on stderr (only when it is a
# TTY, so piped/non-interactive output stays clean) and clear it on first token.
# stderr keeps it out of the captured reply, which is built only from stdout.
_chat_think_show()  { [ -t 2 ] && printf '%b' "${C_DIM}… pensando${C_RESET}" >&2 || true; }
_chat_think_clear() { [ -t 2 ] && printf '\r\033[K' >&2 || true; }

# One model turn. Mutates caller-scoped `messages` (bash dynamic scope).
# Returns 0 on a non-empty reply, 1 otherwise.
_chat_complete() {
  local input="$1"
  local content="" payload line chunk err_msg first=1

  messages="$(jq --arg c "$input" '. += [{"role":"user","content":$c}]' <<<"$messages")"
  printf '%b\n' "${C_BLUE}$CHAT_NAME ›${C_RESET}"
  _chat_think_show
  if [ "$CHAT_BACKEND" = "cloud" ]; then
    if cloud_stream "$CHAT_SYSFILE" "$messages"; then content="$CLOUD_REPLY"; fi
    [ -z "$content" ] && _chat_think_clear
    printf '\n\n'
    [ -z "$content" ] && { err "cloud request failed or returned empty (check API key / network)"; return 1; }
  else
    payload="$(jq -n --arg m "$CHAT_MODEL" --argjson msgs "$messages" '{model:$m, messages:$msgs, stream:true}')"
    err_msg=""
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      err_msg="$(jq -r '.error // empty' <<<"$line" 2>/dev/null)"
      [ -n "$err_msg" ] && break
      chunk="$(jq -rj '.message.content // empty' <<<"$line" 2>/dev/null)"
      [ -n "$chunk" ] && [ "$first" = 1 ] && { _chat_think_clear; first=0; }
      printf '%s' "$chunk"
      content="$content$chunk"
    done < <(curl -fsS --no-buffer "$OLLAMA_HOST/api/chat" -d "$payload" 2>/dev/null)
    [ "$first" = 1 ] && _chat_think_clear
    printf '\n\n'
    [ -n "$err_msg" ] && { err "model error: $err_msg"; return 1; }
    [ -z "$content" ] && { err "empty response (is the model still loading? try again)"; return 1; }
  fi
  messages="$(jq --arg c "$content" '. += [{"role":"assistant","content":$c}]' <<<"$messages")"
  return 0
}

chat_session() {
  local messages='[]' input
  local once_msg="${CHAT_USER:-Execute this unit for the current project. Follow the skill or role. Produce the draft artifacts in this reply; do not wait for another turn.}"

  # Seed a system message on the local backend (cloud bakes it into CHAT_SYSFILE).
  if [ "$CHAT_BACKEND" != "cloud" ] && [ -n "${CHAT_SEED:-}" ]; then
    messages="$(jq --arg c "$CHAT_SEED" '. += [{"role":"system","content":$c}]' <<<"$messages")"
  fi

  if [ "${CHAT_ONCE:-}" = "1" ]; then
    info "One-shot ${C_BOLD}$CHAT_NAME${C_RESET} (${C_DIM}$CHAT_LABEL${C_RESET})."
    printf '\n'
    _chat_complete "$once_msg" || true
    info "one-shot complete"
    return 0
  fi

  info "Chatting with ${C_BOLD}$CHAT_NAME${C_RESET} (${C_DIM}$CHAT_LABEL${C_RESET}). Type ${C_DIM}/exit${C_RESET} to quit, ${C_DIM}/reset${C_RESET} to clear history."
  printf '\n'

  while true; do
    printf '%b' "${C_GREEN}you ›${C_RESET} "
    IFS= read -r input || break
    case "$input" in
      "")        continue ;;
      "/exit"|"/quit") break ;;
      "/reset")  messages='[]'; info "history cleared"; continue ;;
    esac
    _chat_complete "$input" || true
  done

  printf '\n'
  info "session ended"
}
