# shellcheck shell=bash
# rorcc doctor — verify the local environment can run RoR Command Center on Ollama.

# Total physical RAM in GB (best effort, Linux + macOS).
_total_ram_gb() {
  if [ -r /proc/meminfo ]; then
    awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo
  elif command -v sysctl >/dev/null 2>&1; then
    local bytes; bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    printf '%d' $(( bytes / 1024 / 1024 / 1024 ))
  else
    printf '0'
  fi
}

_recommend_tier() {
  local ram="$1"
  if   [ "$ram" -ge 48 ]; then echo "qwen2.5-coder:32b  (tier: 48GB+)"
  elif [ "$ram" -ge 24 ]; then echo "qwen2.5-coder:14b  (tier: 24-32GB)"
  elif [ "$ram" -ge 8  ]; then echo "qwen2.5-coder:7b   (tier: 8-16GB)"
  else echo "qwen2.5-coder:7b   (warning: <8GB RAM, expect slow/limited results)"
  fi
}

cmd_doctor() {
  local problems=0

  info "RoR Command Center — doctor"
  printf '\n'

  # 1) Framework root
  local root
  if root="$(find_ai_root)"; then
    ok ".ai/ framework found at: ${C_DIM}$root${C_RESET}"
  else
    err "no .ai/ framework found (run from a project created with 'rorcc init')"
    problems=$((problems + 1))
  fi

  # 2) curl (hard dependency of the runner)
  if command -v curl >/dev/null 2>&1; then
    ok "curl present"
  else
    err "curl not found — required to talk to Ollama"
    problems=$((problems + 1))
  fi

  # 3) jq (used to build/parse chat JSON)
  if command -v jq >/dev/null 2>&1; then
    ok "jq present"
  else
    warn "jq not found — 'rorcc agent' needs it. Install: apt install jq | brew install jq"
    problems=$((problems + 1))
  fi

  # 4) Ollama binary
  if ollama_installed; then
    ok "ollama installed ($(ollama --version 2>/dev/null | head -n1))"
  else
    err "ollama not installed — get it at https://ollama.com/  (curl -fsSL https://ollama.com/install.sh | sh)"
    problems=$((problems + 1))
  fi

  # 5) Ollama daemon
  if ollama_running; then
    ok "ollama daemon reachable at $OLLAMA_HOST"
  else
    warn "ollama daemon not reachable at $OLLAMA_HOST — start it with 'ollama serve'"
    problems=$((problems + 1))
  fi

  # 6) RAM + recommended model
  local ram; ram="$(_total_ram_gb)"
  if [ "$ram" -gt 0 ]; then
    info "detected RAM: ${ram}GB — recommended base model: $(_recommend_tier "$ram")"
  else
    warn "could not detect RAM; default base model: $RORCC_DEFAULT_MODEL"
  fi

  # 7) Base model present?
  if ollama_installed && ollama_running; then
    if ollama_has_model "$RORCC_DEFAULT_MODEL"; then
      ok "base model present: $RORCC_DEFAULT_MODEL"
    else
      warn "base model missing: $RORCC_DEFAULT_MODEL — pull it: ollama pull $RORCC_DEFAULT_MODEL"
    fi
  fi

  printf '\n'
  if [ "$problems" -eq 0 ]; then
    ok "all checks passed — try: rorcc build-agent rails-architect"
    return 0
  fi
  warn "$problems item(s) need attention before using 'rorcc agent'"
  return 1
}
