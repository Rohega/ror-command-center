# shellcheck shell=bash
# rorcc — cloud backend (hybrid mode).
# Sends the assembled agent system prompt + conversation to a cloud LLM.
# Supports OpenAI-compatible APIs and Anthropic. Best-effort: providers evolve.
#
# Config:
#   RORCC_CLOUD_PROVIDER   openai | anthropic            (default: openai)
#   RORCC_CLOUD_MODEL      model id (e.g. gpt-4o, claude-3-5-sonnet-latest)
#   RORCC_CLOUD_BASE       OpenAI-compatible base URL    (default: https://api.openai.com/v1)
#   OPENAI_API_KEY / ANTHROPIC_API_KEY

CLOUD_PROVIDER="${RORCC_CLOUD_PROVIDER:-openai}"

# Resolve provider config + verify an API key is present. Sets CLOUD_MODEL.
cloud_check() {
  case "$CLOUD_PROVIDER" in
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] || { err "OPENAI_API_KEY not set (cloud backend)"; return 1; }
      CLOUD_MODEL="${RORCC_CLOUD_MODEL:-gpt-4o}"
      ;;
    anthropic)
      [ -n "${ANTHROPIC_API_KEY:-}" ] || { err "ANTHROPIC_API_KEY not set (cloud backend)"; return 1; }
      CLOUD_MODEL="${RORCC_CLOUD_MODEL:-claude-3-5-sonnet-latest}"
      ;;
    *)
      err "unknown RORCC_CLOUD_PROVIDER: $CLOUD_PROVIDER (use 'openai' or 'anthropic')"
      return 1
      ;;
  esac
}

# cloud_stream <system_file> <messages_json>
# Streams the reply live to stdout and stores the full text in CLOUD_REPLY.
cloud_stream() {
  local sysfile="$1" messages="$2"
  CLOUD_REPLY=""
  local body data chunk line jq_filter
  local -a curl_args

  if [ "$CLOUD_PROVIDER" = "anthropic" ]; then
    body="$(jq -n --arg m "$CLOUD_MODEL" --rawfile sys "$sysfile" --argjson msgs "$messages" \
      '{model:$m, system:$sys, stream:true, max_tokens:4096, messages:$msgs}')"
    curl_args=(
      -H "x-api-key: $ANTHROPIC_API_KEY"
      -H "anthropic-version: 2023-06-01"
      -H "content-type: application/json"
      "https://api.anthropic.com/v1/messages"
    )
    jq_filter='select(.type=="content_block_delta") | .delta.text // empty'
  else
    body="$(jq -n --arg m "$CLOUD_MODEL" --rawfile sys "$sysfile" --argjson msgs "$messages" \
      '{model:$m, stream:true, messages: ([{role:"system",content:$sys}] + $msgs)}')"
    curl_args=(
      -H "Authorization: Bearer $OPENAI_API_KEY"
      -H "content-type: application/json"
      "${RORCC_CLOUD_BASE:-https://api.openai.com/v1}/chat/completions"
    )
    jq_filter='.choices[0].delta.content // empty'
  fi

  local first=1
  while IFS= read -r line; do
    case "$line" in
      "data: [DONE]") break ;;
      data:*) data="${line#data: }" ;;
      *) continue ;;
    esac
    chunk="$(jq -rj "$jq_filter" <<<"$data" 2>/dev/null)" || continue
    # Clear the "thinking" hint (defined in chat.sh) once real output starts.
    [ -n "$chunk" ] && [ "$first" = 1 ] && { type _chat_think_clear >/dev/null 2>&1 && _chat_think_clear; first=0; }
    printf '%s' "$chunk"
    CLOUD_REPLY="$CLOUD_REPLY$chunk"
  done < <(curl -fsS --no-buffer -X POST "${curl_args[@]}" -d "$body" 2>/dev/null)

  [ -n "$CLOUD_REPLY" ]
}
