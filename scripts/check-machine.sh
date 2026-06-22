#!/usr/bin/env bash
# RoR Command Center — machine readiness check for local llama models (Ollama).
#
# Reports OS, RAM, CPU, free disk, and GPU, then recommends a model tier and
# tells you whether the machine can run the local specialists.
#
# Standalone (no repo/.ai/ required) so it can run on ANY machine before install:
#   bash scripts/check-machine.sh
#   curl -fsSL <url>/scripts/check-machine.sh | bash
#
# Also sourceable: setup.sh sources it to reuse the detection + tier logic.
#   . scripts/check-machine.sh   # defines mc_* functions, does not run the report
#
# Exit code (when run directly): 0 = ready (RAM >= 8GB), 1 = not recommended.
set -euo pipefail

# --- Colors (disabled when not a TTY) -----------------------------------------
if [ -t 1 ]; then
  MC_RESET="\033[0m"; MC_DIM="\033[2m"; MC_GREEN="\033[32m"; MC_YELLOW="\033[33m"
  MC_BLUE="\033[34m"; MC_RED="\033[31m"; MC_BOLD="\033[1m"
else
  MC_RESET=""; MC_DIM=""; MC_GREEN=""; MC_YELLOW=""; MC_BLUE=""; MC_RED=""; MC_BOLD=""
fi

# --- Detection helpers (best effort: Linux, macOS, WSL2) ----------------------

# Total physical RAM in GB (integer, rounded down).
mc_ram_gb() {
  if [ -r /proc/meminfo ]; then
    awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo
  elif command -v sysctl >/dev/null 2>&1; then
    printf '%d' $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
  else
    printf '0'
  fi
}

# Logical CPU count.
mc_cpu() {
  if command -v nproc >/dev/null 2>&1; then nproc
  elif command -v sysctl >/dev/null 2>&1; then sysctl -n hw.ncpu 2>/dev/null || echo 0
  else echo 0; fi
}

# Free disk space in GB for $HOME (where Ollama stores models, ~/.ollama).
mc_disk_avail_gb() {
  df -Pk "$HOME" 2>/dev/null | awk 'NR==2 {printf "%d", $4/1024/1024}'
}

# GPU description, or empty if none detected.
mc_gpu() {
  if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -n1
  elif [ "$(uname -s)" = "Darwin" ] && command -v system_profiler >/dev/null 2>&1; then
    system_profiler SPDisplaysDataType 2>/dev/null | awk -F': ' '/Chipset Model/ {print $2; exit}'
  fi
}

# Recommended base model for a RAM size (matches README + rorcc doctor tiers).
mc_pick_model() {
  local r="${1:-0}"
  if   [ "$r" -ge 48 ]; then echo "qwen2.5-coder:32b"
  elif [ "$r" -ge 24 ]; then echo "qwen2.5-coder:14b"
  else echo "qwen2.5-coder:7b"; fi
}

# Approx disk needed (GB) by the model tier picked for a RAM size.
mc_model_disk_gb() {
  local r="${1:-0}"
  if   [ "$r" -ge 48 ]; then echo 20
  elif [ "$r" -ge 24 ]; then echo 9
  else echo 5; fi
}

# --- Report -------------------------------------------------------------------
# Prints a human-readable readiness report. Returns 0 if RAM >= 8GB, else 1.
mc_report() {
  local ram cpu disk gpu model need
  ram="$(mc_ram_gb)"; cpu="$(mc_cpu)"; disk="$(mc_disk_avail_gb)"
  gpu="$(mc_gpu)"; model="$(mc_pick_model "$ram")"; need="$(mc_model_disk_gb "$ram")"

  printf '%b\n' "${MC_BOLD}Chequeo de equipo — modelos de IA local (Ollama)${MC_RESET}"
  printf '  %-14s %s\n' "Sistema:" "$(uname -srm)"
  printf '  %-14s %s GB\n' "RAM:" "$ram"
  printf '  %-14s %s\n' "CPU (núcleos):" "$cpu"
  printf '  %-14s %s GB libres\n' "Disco:" "${disk:-?}"
  if [ -n "$gpu" ]; then
    printf '  %-14s %s\n' "GPU:" "$gpu"
  else
    printf '  %-14s %s\n' "GPU:" "ninguna detectada (usará CPU/RAM)"
  fi
  printf '\n'

  # RAM verdict.
  if [ "$ram" -le 0 ]; then
    printf '%b\n' "${MC_YELLOW}!${MC_RESET}    No pude detectar la RAM; modelo por defecto: ${MC_BOLD}qwen2.5-coder:7b${MC_RESET}"
  elif [ "$ram" -lt 8 ]; then
    printf '%b\n' "${MC_RED}✗${MC_RESET}    RAM baja (${ram} GB). No recomendado: la IA irá lenta o no cargará. Ideal: 8 GB+."
  else
    printf '%b\n' "${MC_GREEN}✓${MC_RESET}    RAM suficiente para: ${MC_BOLD}${model}${MC_RESET}"
  fi

  # Disk verdict.
  if [ -n "$disk" ] && [ "$disk" -lt "$need" ]; then
    printf '%b\n' "${MC_YELLOW}!${MC_RESET}    Disco ajustado: el modelo necesita ~${need} GB y tienes ${disk} GB libres."
  elif [ -n "$disk" ]; then
    printf '%b\n' "${MC_GREEN}✓${MC_RESET}    Disco suficiente (~${need} GB para el modelo, ${disk} GB libres)."
  fi

  # GPU note.
  if [ -n "$gpu" ]; then
    printf '%b\n' "${MC_BLUE}==>${MC_RESET} La GPU acelera la inferencia (offload parcial si su VRAM es menor que el modelo)."
  fi

  printf '\n'
  if [ "$ram" -ge 8 ] || [ "$ram" -le 0 ]; then
    printf '%b\n' "${MC_GREEN}Listo:${MC_RESET} este equipo puede correr ${MC_BOLD}${model}${MC_RESET}."
    return 0
  fi
  printf '%b\n' "${MC_RED}Atención:${MC_RESET} este equipo no cumple el mínimo recomendado (8 GB RAM)."
  return 1
}

# --- Run only when executed directly, not when sourced ------------------------
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  mc_report
fi
