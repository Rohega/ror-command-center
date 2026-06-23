# shellcheck shell=bash
# RoR Command Center — shared helpers for the rorcc CLI.
# Sourced by bin/rorcc and the lib/rorcc/*.sh subcommands.

# --- Colors (disabled when not a TTY) -----------------------------------------
if [ -t 1 ]; then
  C_RESET="\033[0m"; C_DIM="\033[2m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"
  C_BLUE="\033[34m"; C_RED="\033[31m"; C_BOLD="\033[1m"
else
  C_RESET=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RED=""; C_BOLD=""
fi

info() { printf '%b\n' "${C_BLUE}==>${C_RESET} $1"; }
ok()   { printf '%b\n' "${C_GREEN}ok${C_RESET}   $1"; }
warn() { printf '%b\n' "${C_YELLOW}!${C_RESET}    $1"; }
err()  { printf '%b\n' "${C_RED}error:${C_RESET} $1" >&2; }

# --- Configuration ------------------------------------------------------------
# Default local model. Override with RORCC_MODEL or --model.
RORCC_DEFAULT_MODEL="${RORCC_MODEL:-qwen2.5-coder:7b}"
OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

# --- Framework root detection -------------------------------------------------
# The framework lives wherever ".ai/agents" is. We look (1) up from the current
# directory, then (2) relative to the installed CLI location.
find_ai_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.ai/agents" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  # Fallback: relative to this lib dir (repo checkout: <root>/lib/rorcc/..).
  if [ -d "$RORCC_LIB_DIR/../../.ai/agents" ]; then
    (cd "$RORCC_LIB_DIR/../.." && pwd)
    return 0
  fi
  return 1
}

# Resolve the framework root or fail with an actionable message. Commands that
# read .ai/ must run inside a project created with 'rorcc init' or the cloned repo.
require_ai_root() {
  local root
  if root="$(find_ai_root)"; then
    printf '%s\n' "$root"
    return 0
  fi
  err "no .ai/ framework found — run this inside your project folder (created with 'rorcc init <name>') or inside the cloned RoR Command Center repo."
  return 1
}

# --- Ollama helpers -----------------------------------------------------------
ollama_installed() { command -v ollama >/dev/null 2>&1; }

ollama_running() {
  curl -fsS "$OLLAMA_HOST/api/tags" >/dev/null 2>&1
}

# True if a model is present locally. Matches whether or not "$1" carries a tag:
# Ollama tags created models as "<name>:latest", so we compare against both the
# full "name:tag" and the bare name. grep -Fxq keeps it a literal whole-line match
# (model names like "qwen2.5-coder" contain regex metacharacters).
ollama_has_model() {
  local model="$1"
  ollama list 2>/dev/null \
    | awk 'NR > 1 { print $1; if (sub(/:.*/, "", $1)) print $1 }' \
    | grep -Fxq "$model"
}
