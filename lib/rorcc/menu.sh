# shellcheck shell=bash
# rorcc menu — friendly interactive launcher for non-technical users.
# Lists the specialists by number; picking one opens a local chat.

# Display name (Spanish) → agent slug. Parallel arrays keep it POSIX-friendly.
_MENU_LABELS=(
  "Arquitecto Rails"
  "Programador Backend"
  "Programador Frontend"
  "Ingeniero DevOps (AWS)"
  "Ingeniero de Calidad (QA)"
  "Redactor de Documentación"
  "Product Owner"
  "Ingeniero de Seguridad"
)
_MENU_SLUGS=(
  "rails-architect"
  "backend-rails-developer"
  "frontend-react-inertia-developer"
  "aws-devops-engineer"
  "qa-engineer"
  "documentation-writer"
  "product-owner"
  "security-reviewer"
)

cmd_menu() {
  # If the environment isn't ready, guide the user instead of failing cryptically.
  if ! ollama_running || ! command -v jq >/dev/null 2>&1; then
    warn "El entorno aún no está listo para chatear."
    info "Ejecuta el instalador fácil (setup.sh) o revisa el estado:"
    printf '\n'
    . "$RORCC_LIB_DIR/doctor.sh"
    cmd_doctor || true
    return 1
  fi

  while true; do
    printf '\n'
    printf '%b\n' "${C_BOLD}RoR Command Center — ¿con quién quieres hablar?${C_RESET}"
    printf '\n'
    local i
    for i in "${!_MENU_LABELS[@]}"; do
      printf '  %b%d)%b %s\n' "$C_BLUE" "$((i + 1))" "$C_RESET" "${_MENU_LABELS[$i]}"
    done
    printf '  %bq)%b Salir\n\n' "$C_DIM" "$C_RESET"
    printf '%b' "Elige un número: "

    local choice
    IFS= read -r choice || break
    case "$choice" in
      q|Q|"") break ;;
      *[!0-9]*) warn "Opción no válida: $choice"; continue ;;
    esac

    local idx=$((choice - 1))
    if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#_MENU_SLUGS[@]}" ]; then
      warn "Número fuera de rango: $choice"; continue
    fi

    local slug="${_MENU_SLUGS[$idx]}"
    # Build the agent on demand if it isn't compiled yet.
    if ! ollama_has_model "rorcc-$slug"; then
      info "Preparando a '${_MENU_LABELS[$idx]}' por primera vez..."
      . "$RORCC_LIB_DIR/build_agent.sh"
      cmd_build_agent "$slug" || { err "no se pudo preparar el experto"; continue; }
    fi

    . "$RORCC_LIB_DIR/agent.sh"
    cmd_agent "$slug"
  done

  printf '\n'
  info "¡Hasta luego!"
}
