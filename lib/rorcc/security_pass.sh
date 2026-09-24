# shellcheck shell=bash
# rorcc security — phase 3. Structured findings, only when the DoD already requires them.
# Cites only files this pass opened. See ADR-0008.

_security_required() {
  local size="$1" signals="$2"
  case "$size" in
    L|XL) return 0 ;;
  esac
  case ",$signals," in
    *,auth_changed,*) return 0 ;;
  esac
  return 1
}

_security_scan_file() {
  local file="$1" line
  case "$file" in
    ""|/*|..|../*|*/../*|*/..) err "refusing path: $file"; return 1 ;;
  esac
  [ -f "$file" ] || return 0
  SECURITY_OPENED="${SECURITY_OPENED:+$SECURITY_OPENED,}$file"
  while IFS= read -r line || [ -n "$line" ]; do
    if printf '%s' "$line" | grep -Eq "(password|api_key|secret)[[:space:]]*=[[:space:]]*['\"][^'\"]+['\"]"; then
      SECURITY_FINDINGS="${SECURITY_FINDINGS}title: Hard-coded credential"$'\n'"level: high"$'\n'"risk: A password or key in source can be copied from the repository."$'\n'"files: $file"$'\n'"---"$'\n'
    elif printf '%s' "$line" | grep -Eq "where[[:space:]]*\([[:space:]]*['\"].*#\{"; then
      SECURITY_FINDINGS="${SECURITY_FINDINGS}title: SQL built with interpolation"$'\n'"level: high"$'\n'"risk: User input folded into a SQL string can change the query."$'\n'"files: $file"$'\n'"---"$'\n'
    fi
  done <"$file"
}

cmd_security() {
  local size="M" signals="" paths=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --size) shift; size="${1:-}" ;;
      --signals) shift; signals="${1:-}" ;;
      --paths) shift; paths="${1:-}" ;;
      -*) err "unknown option: $1"; return 2 ;;
      *) err "unexpected argument: $1"; return 2 ;;
    esac
    shift
  done
  case "$size" in
    S|M|L|XL) ;;
    *) err "usage: --size S|M|L|XL"; return 2 ;;
  esac

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found — run this inside your project folder."; return 1; }
  case "$PWD/" in
    "$root"/*|"$root/") ;;
    *) err "run security inside the project that contains .ai/"; return 1 ;;
  esac
  cd "$root" || return 1

  if ! _security_required "$size" "$signals"; then
    printf 'security pass skipped\n'
    return 0
  fi

  SECURITY_OPENED=""
  SECURITY_FINDINGS=""
  if [ -n "$paths" ]; then
    local p
    local IFS=','
    for p in $paths; do
      _security_scan_file "$p"
    done
  else
    local changed
    changed="$(git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)"
    local f
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      case "$f" in
        *.rb|*.erb|*.js|*.yml|*.yaml|*.rake) _security_scan_file "$f" ;;
      esac
    done <<<"$changed"
  fi

  local stamp path
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  path="docs/security/findings-$stamp.md"
  mkdir -p docs/security
  {
    printf '# Security findings\n\n'
    printf -- '- opened: %s\n\n' "${SECURITY_OPENED:-none}"
    if [ -z "$SECURITY_FINDINGS" ]; then
      printf 'No findings in the files this pass opened.\n'
    else
      printf '%s\n' "$SECURITY_FINDINGS"
    fi
  } >"$path"
  printf 'security findings: %s\n' "$path"
}
