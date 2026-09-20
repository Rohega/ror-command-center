# shellcheck shell=bash
# One-shot request classifier for workflow V3. Heuristic only (0 LLM).
# Sets WF_SIZE, WF_SIG_*, WF_CLASS_REASON. Does not route, write, or invoke skills.

_classify_reset_signals() {
  WF_SIG_user_behavior_changed=0
  WF_SIG_database_changed=0
  WF_SIG_api_changed=0
  WF_SIG_auth_changed=0
  WF_SIG_architecture_changed=0
  WF_SIG_setup_changed=0
  WF_SIG_infrastructure_changed=0
}

_classify_reset() {
  WF_SIZE=M
  WF_CLASS_REASON=""
  _classify_reset_signals
}

_classify_apply_signals() {
  local csv="${1:-}" item
  while IFS= read -r item; do
    case "$item" in
      user_behavior_changed) WF_SIG_user_behavior_changed=1 ;;
      database_changed) WF_SIG_database_changed=1 ;;
      api_changed) WF_SIG_api_changed=1 ;;
      auth_changed) WF_SIG_auth_changed=1 ;;
      architecture_changed) WF_SIG_architecture_changed=1 ;;
      setup_changed) WF_SIG_setup_changed=1 ;;
      infrastructure_changed) WF_SIG_infrastructure_changed=1 ;;
      "") ;;
      *)
        err "unknown signal: $item"
        return 2
        ;;
    esac
  done < <(_each_csv "$csv")
}

_classify_bool() {
  [ "${1:-0}" = "1" ] && printf 'true' || printf 'false'
}

# Compact report (tests + --plan).
_classify_format() {
  printf 'size: %s\n' "${WF_SIZE:-M}"
  printf 'signals:\n'
  printf '  user_behavior_changed: %s\n' "$(_classify_bool "${WF_SIG_user_behavior_changed:-0}")"
  printf '  database_changed: %s\n' "$(_classify_bool "${WF_SIG_database_changed:-0}")"
  printf '  api_changed: %s\n' "$(_classify_bool "${WF_SIG_api_changed:-0}")"
  printf '  auth_changed: %s\n' "$(_classify_bool "${WF_SIG_auth_changed:-0}")"
  printf '  architecture_changed: %s\n' "$(_classify_bool "${WF_SIG_architecture_changed:-0}")"
  printf '  setup_changed: %s\n' "$(_classify_bool "${WF_SIG_setup_changed:-0}")"
  printf '  infrastructure_changed: %s\n' "$(_classify_bool "${WF_SIG_infrastructure_changed:-0}")"
  printf 'reason: "%s"\n' "${WF_CLASS_REASON:-}"
}

# _classify_request <text>
# Keyword heuristic. Size ≠ risk: signals are independent. "login" as a label
# does not set auth_changed.
_classify_request() {
  _classify_reset
  local t
  t="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"

  if printf '%s' "$t" | grep -Eq \
    'filtro|filter by|filter for|flujo|workflow|formulario|\bforms?\b|redir|naveg|inicia otro|starts? another|nueva acci[oó]n|new action|checkbox|paginaci|sort by|ordenar por|bot[oó]n ahora|button now|inicia un|starts a new'; then
    WF_SIG_user_behavior_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    'migraci[oó]n|migration|add_column|create_table|esquema|\bschema\b|nueva tabla|new table|nueva columna|new column|[ií]ndice |\bindex on\b|foreign key'; then
    WF_SIG_database_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    'endpoint|serializer|api rest|rest api|/api/|graphql|json api'; then
    WF_SIG_api_changed=1
  fi

  # Do not match bare "login" / "entrar" (button copy).
  if printf '%s' "$t" | grep -Eq \
    'devise|pundit|oauth|openid|\bjwt\b|\bmfa\b|\b2fa\b|autorizaci[oó]n|authorization|autenticaci[oó]n|authentication|pol[ií]tica de contrase[nñ]a|password policy|permisos? de|permissions?|\brbac\b|session timeout|secure cookie'; then
    WF_SIG_auth_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    'solid queue|sidekiq|arquitectura|architecture|cambiar de motor|replace (the )?queue|reemplazar .+ por'; then
    WF_SIG_architecture_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    'paso (obligatorio )?de (setup|instalaci)|setup step|variable de entorno|env var|\.env|onboarding|instalaci[oó]n obligat'; then
    WF_SIG_setup_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    '\baws\b|terraform|kamal|capistrano|\bdocker\b|nginx|\brds\b|\becs\b|\beks\b|deploy(ment)? to prod|infraestructur|infrastructure'; then
    WF_SIG_infrastructure_changed=1
  fi

  if printf '%s' "$t" | grep -Eq \
    'solid queue|migrar .+ a |migrate .+ to |reescribir|\brewrite\b|redise[nñ]o arquitect|reemplazar sidekiq|replace sidekiq'; then
    WF_SIZE=XL
    WF_SIG_architecture_changed=1
    WF_CLASS_REASON="Architectural migration or platform replacement."
  elif printf '%s' "$t" | grep -Eq \
    'm[oó]dulo de|nuevo m[oó]dulo|new module|solicitudes y aprobaci|approval (of|workflow)|nueva [aá]rea|multi-tenant'; then
    WF_SIZE=L
    WF_SIG_user_behavior_changed=1
    WF_SIG_database_changed=1
    WF_CLASS_REASON="Significant feature area with multiple behaviors."
  elif printf '%s' "$t" | grep -Eq \
    'texto|color|\bcopy\b|label|r[oó]tulo|tipograf|placeholder|traduc|\btypo\b|padding|margen|css only|solo (el )?estilo'; then
    WF_SIZE=S
    WF_CLASS_REASON="Trivial local copy or visual change."
  elif printf '%s' "$t" | grep -Eq \
    'agregar |a[nñ]adir |\badd |\bnuevo filtro|new filter|nueva validaci|new field'; then
    WF_SIZE=M
    WF_CLASS_REASON="Bounded new behavior."
    if printf '%s' "$t" | grep -Eq 'filtro|filter|flujo|form'; then
      WF_SIG_user_behavior_changed=1
    fi
  else
    WF_SIZE=M
    WF_CLASS_REASON="Default bounded change; override with --size if wrong."
  fi

  # Size ≠ risk: copy+behavior is M; copy+auth stays S with auth_changed.
  if [ "$WF_SIZE" = S ] && [ "${WF_SIG_user_behavior_changed:-0}" = "1" ]; then
    WF_SIZE=M
    WF_CLASS_REASON="User-visible behavior change (not copy-only)."
  fi
  if [ "$WF_SIZE" = S ] && [ "${WF_SIG_auth_changed:-0}" = "1" ]; then
    WF_CLASS_REASON="Trivial surface change with auth impact."
  fi
}
