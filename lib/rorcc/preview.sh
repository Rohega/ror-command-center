# shellcheck shell=bash
# rorcc preview — phase 4. Refresh or restart the app docker compose already serves.
# The preview is not the Definition of Done. See ADR-0009.

_preview_compose() {
  if [ -f docker-compose.yml ]; then printf '%s\n' docker-compose.yml; return 0; fi
  if [ -f compose.yml ]; then printf '%s\n' compose.yml; return 0; fi
  return 1
}

_preview_url() {
  local port="3000" line
  if [ -f .env ]; then
    line="$(grep -E '^RAILS_PORT=' .env | tail -1 || true)"
    line="${line#RAILS_PORT=}"
    line="${line%\"}"
    line="${line#\"}"
    [ -n "$line" ] && port="$line"
  fi
  printf 'http://localhost:%s\n' "$port"
}

cmd_preview() {
  local action="${1:-status}"
  case "$action" in
    status|refresh|restart) ;;
    -*) err "unknown option: $action"; return 2 ;;
    *) err "usage: rorcc preview [refresh|restart]"; return 2 ;;
  esac

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found — run this inside your project folder."; return 1; }
  case "$PWD/" in
    "$root"/*|"$root/") ;;
    *) err "run preview inside the project that contains .ai/"; return 1 ;;
  esac
  cd "$root" || return 1

  local compose; compose="$(_preview_compose)" || { err "no docker-compose.yml in this project"; return 1; }
  local url; url="$(_preview_url)"

  case "$action" in
    status)
      printf 'preview: %s\n' "$url"
      if curl -fsS -o /dev/null --max-time 2 "$url" 2>/dev/null; then
        printf 'preview status: up\n'
      else
        printf 'preview status: down\n'
      fi
      ;;
    refresh)
      if curl -fsS -o /dev/null --max-time 5 "$url" 2>/dev/null; then
        printf 'preview refreshed: %s\n' "$url"
      else
        err "preview is not up at $url"
        return 1
      fi
      ;;
    restart)
      local docker_bin="${RORCC_DOCKER:-docker}"
      command -v "$docker_bin" >/dev/null 2>&1 || { err "Docker is not available"; return 1; }
      "$docker_bin" compose -f "$compose" restart web || return 1
      printf 'preview restarted: %s\n' "$url"
      ;;
  esac
}
