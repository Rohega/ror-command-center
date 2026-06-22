#!/usr/bin/env bash
# RoR Command Center — easy setup (plug-and-play for non-technical users).
#
# One command does everything: installs Ollama, a local AI model, the rorcc CLI,
# and compiles the specialist agents. Designed for Linux, macOS, and Windows+WSL.
#
#   curl -fsSL https://raw.githubusercontent.com/Rohega/ror-command-center/main/setup.sh | bash
#
# Idempotent: re-running only completes what is missing.
set -euo pipefail

# --- Colors -------------------------------------------------------------------
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
step() { printf '\n%b\n' "${C_BOLD}$1${C_RESET}"; }

OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"

# --- Locate the framework root ------------------------------------------------
# Works whether run from a clone (./setup.sh) or piped (curl | bash from a clone).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || pwd)"
if [ -d "$SCRIPT_DIR/.ai/agents" ]; then
  ROOT="$SCRIPT_DIR"
elif [ -d "$PWD/.ai/agents" ]; then
  ROOT="$PWD"
else
  ROOT="$SCRIPT_DIR"
fi

# Reuse the standalone machine check when available (defines mc_* helpers and
# mc_report). Sourcing does not run the report — we call it in the intro below.
if [ -f "$ROOT/scripts/check-machine.sh" ]; then
  # shellcheck source=/dev/null
  . "$ROOT/scripts/check-machine.sh"
fi

# --- OS / package manager detection -------------------------------------------
OS="$(uname -s)"
detect_pkg() {
  if   command -v brew    >/dev/null 2>&1; then echo "brew";
  elif command -v apt-get >/dev/null 2>&1; then echo "apt";
  elif command -v dnf     >/dev/null 2>&1; then echo "dnf";
  elif command -v pacman  >/dev/null 2>&1; then echo "pacman";
  else echo ""; fi
}
PKG="$(detect_pkg)"

# --- RAM detection + model tier ----------------------------------------------
ram_gb() {
  if [ -r /proc/meminfo ]; then
    awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo
  elif command -v sysctl >/dev/null 2>&1; then
    printf '%d' $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
  else echo 0; fi
}
pick_model() {
  local r="$1"
  if   [ "$r" -ge 48 ]; then echo "qwen2.5-coder:32b";
  elif [ "$r" -ge 24 ]; then echo "qwen2.5-coder:14b";
  else echo "qwen2.5-coder:7b"; fi
}

RAM="$(ram_gb)"
MODEL="${RORCC_MODEL:-$(pick_model "$RAM")}"

# --- Helpers ------------------------------------------------------------------
have()           { command -v "$1" >/dev/null 2>&1; }
ollama_running() { curl -fsS "$OLLAMA_HOST/api/tags" >/dev/null 2>&1; }
has_model()      { ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$1"; }

install_pkg() {
  local pkg="$1"
  case "$PKG" in
    brew)   brew install "$pkg" ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y "$pkg" ;;
    dnf)    sudo dnf install -y "$pkg" ;;
    pacman) sudo pacman -S --noconfirm "$pkg" ;;
    *)      return 1 ;;
  esac
}

# --- Intro + single confirmation ---------------------------------------------
printf '%b\n' "${C_BOLD}RoR Command Center — instalación fácil${C_RESET}"
cat <<EOF

Esto preparará tu PC para usar IA local (sin nube, sin costo):

  • Instala Ollama (motor de IA local) si falta
  • Instala 'jq' (utilidad pequeña) si falta
  • Descarga un modelo de IA — ${C_BOLD}varios GB${C_RESET}, puede tardar
  • Deja listo el comando 'rorcc' y a los especialistas
EOF
printf '\n'
if command -v mc_report >/dev/null 2>&1; then
  mc_report || true
else
  printf '%b\n' "Sistema:  $OS   ·   RAM: ${RAM}GB   ·   Modelo elegido: $MODEL"
  if [ "$RAM" -gt 0 ] && [ "$RAM" -lt 8 ]; then
    warn "Tu RAM (${RAM}GB) es baja; la IA puede ir lenta. Recomendado: 8GB+."
  fi
fi
case "$OS" in
  Linux|Darwin) : ;;
  *) printf '\n'; err "Sistema no soportado por este script ($OS). En Windows usa WSL."; exit 1 ;;
esac

printf '\n'
# Respect non-interactive use: RORCC_YES=1 skips the prompt (also when piped without a TTY).
if [ "${RORCC_YES:-0}" != "1" ] && [ -t 0 ]; then
  printf '%b' "¿Continuar? [s/N]: "
  IFS= read -r ans
  case "$ans" in s|S|si|SI|y|Y) : ;; *) info "Cancelado."; exit 0 ;; esac
elif [ ! -t 0 ] && [ "${RORCC_YES:-0}" != "1" ]; then
  warn "Ejecución no interactiva sin RORCC_YES=1. Re-ejecuta así para aceptar:"
  warn "  curl -fsSL <url>/setup.sh | RORCC_YES=1 bash"
  exit 0
fi

# --- Step 1: Ollama -----------------------------------------------------------
step "1/5  Ollama (motor de IA local)"
if have ollama; then
  ok "Ollama ya instalado ($(ollama --version 2>/dev/null | head -n1))"
else
  info "Instalando Ollama (puede pedir tu contraseña)..."
  if [ "$OS" = "Darwin" ] && [ "$PKG" = "brew" ]; then
    brew install ollama || curl -fsSL https://ollama.com/install.sh | sh
  else
    curl -fsSL https://ollama.com/install.sh | sh
  fi
  have ollama && ok "Ollama instalado" || { err "no se pudo instalar Ollama"; exit 1; }
fi

# --- Step 2: jq ---------------------------------------------------------------
step "2/5  Utilidad 'jq'"
if have jq; then
  ok "jq ya instalado"
elif [ -n "$PKG" ]; then
  info "Instalando jq..."
  install_pkg jq && ok "jq instalado" || warn "no se pudo instalar jq automáticamente"
else
  warn "no detecté gestor de paquetes; instala 'jq' manualmente"
fi

# --- Step 3: daemon -----------------------------------------------------------
step "3/5  Servidor de Ollama"
if ollama_running; then
  ok "el servidor de Ollama ya está corriendo"
else
  info "iniciando el servidor de Ollama..."
  nohup ollama serve >/dev/null 2>&1 &
  for _ in $(seq 1 20); do ollama_running && break; sleep 1; done
  ollama_running && ok "servidor listo" || warn "no respondió aún; ejecuta 'ollama serve' si falla"
fi

# --- Step 4: model ------------------------------------------------------------
step "4/5  Modelo de IA ($MODEL)"
if has_model "$MODEL"; then
  ok "el modelo ya está descargado"
else
  info "descargando $MODEL (varios GB, paciencia)..."
  ollama pull "$MODEL" && ok "modelo descargado" || { err "no se pudo descargar el modelo"; exit 1; }
fi

# --- Step 5: rorcc CLI + agents ----------------------------------------------
step "5/5  Comando 'rorcc' y especialistas"
if [ -f "$ROOT/install.sh" ]; then
  bash "$ROOT/install.sh" --install-cli
else
  warn "no encontré install.sh; ejecuta este script desde el repo clonado"
fi

RORCC="$ROOT/cli/rorcc"
if [ -x "$RORCC" ]; then
  info "preparando especialistas (esto solo se hace una vez)..."
  for slug in rails-architect backend-rails-developer frontend-react-inertia-developer \
              aws-devops-engineer qa-engineer documentation-writer product-owner security-reviewer; do
    RORCC_MODEL="$MODEL" "$RORCC" build-agent "$slug" >/dev/null 2>&1 \
      && ok "listo: $slug" || warn "no se pudo preparar: $slug"
  done
else
  warn "no encontré cli/rorcc; omito la compilación de especialistas"
fi

# --- Done ---------------------------------------------------------------------
printf '\n'
ok "${C_BOLD}¡Todo listo!${C_RESET} Para empezar a chatear, escribe:"
printf '\n    %brorcc%b\n\n' "$C_GREEN" "$C_RESET"
info "Si 'rorcc' no se encuentra, abre una terminal nueva o agrega ~/.local/bin a tu PATH."
