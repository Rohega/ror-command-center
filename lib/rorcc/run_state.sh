#!/usr/bin/env bash
# Persistent workflow run metadata and safe resume helpers. Sourced by workflow.sh.

_run_meta_put() {
  local file="$1" key="$2" value="${3:-}"
  value="${value//$'\t'/ }"
  value="${value//$'\n'/ }"
  printf '%s\t%s\n' "$key" "$value" >> "$file"
}

_run_meta_get() {
  local file="$1" key="$2"
  awk -F'\t' -v key="$key" '
    $1==key {
      pos=index($0,"\t")
      if(pos>0) print substr($0,pos+1)
      exit
    }
  ' "$file"
}

_run_git_branch() {
  local root="$1"
  if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$root" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'DETACHED\n'
  else
    printf 'none\n'
  fi
}

_run_git_head() {
  local root="$1"
  git -C "$root" rev-parse HEAD 2>/dev/null || printf 'none\n'
}

_run_workflow_checksum() {
  local wf="$1"
  cksum "$wf" | awk '{printf "%s:%s\n",$1,$2}'
}

_run_active_signals() {
  local out="" sig var
  for sig in user_behavior_changed database_changed api_changed auth_changed architecture_changed setup_changed infrastructure_changed; do
    var="WF_SIG_$sig"
    if [ "${!var:-0}" = "1" ]; then
      out="${out:+$out,}$sig"
    fi
  done
  printf '%s\n' "$out"
}

_write_run_metadata() {
  local file="$1" workflow="$2" wf="$3" root="$4" auto="$5" backend_flag="$6"
  local backend="default"
  [ "$backend_flag" = "--cloud" ] && backend="cloud"
  [ "$backend_flag" = "--local" ] && backend="local"

  : > "$file"
  _run_meta_put "$file" workflow "$workflow"
  _run_meta_put "$file" workflow_checksum "$(_run_workflow_checksum "$wf")"
  _run_meta_put "$file" branch "$(_run_git_branch "$root")"
  _run_meta_put "$file" head_sha "$(_run_git_head "$root")"
  _run_meta_put "$file" classified "${WF_CLASSIFY:-0}"
  _run_meta_put "$file" size "${WF_SIZE:-}"
  _run_meta_put "$file" signals "$(_run_active_signals)"
  _run_meta_put "$file" only "${WF_ONLY:-}"
  _run_meta_put "$file" skip "${WF_SKIP:-}"
  _run_meta_put "$file" full "${WF_FULL:-0}"
  _run_meta_put "$file" auto "$auto"
  _run_meta_put "$file" backend "$backend"
}

_latest_resumable_run() {
  local root="$1" runs id
  runs="$root/.rorcc/runs"
  [ -d "$runs" ] || return 1
  while IFS= read -r id; do
    [ -f "$runs/$id/metadata.tsv" ] && [ -f "$runs/$id/state.tsv" ] || continue
    printf '%s\n' "$id"
    return 0
  done < <(ls -1 "$runs" 2>/dev/null | sort -r)
  return 1
}

_resume_validate() {
  local root="$1" wf="$2" meta="$3" force="$4"
  local expected current invalid=0

  expected="$(_run_meta_get "$meta" workflow_checksum)"
  current="$(_run_workflow_checksum "$wf")"
  if [ "$expected" != "$current" ]; then
    warn "resume safety: workflow definition changed"
    invalid=1
  fi

  expected="$(_run_meta_get "$meta" branch)"
  current="$(_run_git_branch "$root")"
  if [ "$expected" != "$current" ]; then
    warn "resume safety: branch changed ($expected -> $current)"
    invalid=1
  fi

  expected="$(_run_meta_get "$meta" head_sha)"
  current="$(_run_git_head "$root")"
  if [ "$expected" != "$current" ]; then
    warn "resume safety: git HEAD changed"
    invalid=1
  fi

  if [ "$invalid" -ne 0 ] && [ "$force" -ne 1 ]; then
    err "run cannot be resumed safely; inspect the changes or retry with --force"
    return 1
  fi
  [ "$invalid" -ne 0 ] && warn "--force accepted changed repository state"
  return 0
}

_cmd_workflow_resume() {
  local requested="${1:-latest}" force=0 auto_override="" backend_override=""
  local root run_id run_dir meta workflow classified size signals only skip full auto backend wf
  local -a args

  [ $# -gt 0 ] && shift || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --auto) auto_override="1" ;;
      --force) force=1 ;;
      --cloud) backend_override="cloud" ;;
      --local) backend_override="local" ;;
      -*) err "unknown resume option: $1"; return 2 ;;
      *) err "unexpected resume argument: $1"; return 2 ;;
    esac
    shift
  done

  root="$(require_ai_root)" || return 1
  if [ "$requested" = "latest" ]; then
    run_id="$(_latest_resumable_run "$root")" || {
      err "no resumable workflow run found"
      return 1
    }
  else
    run_id="$requested"
  fi

  run_dir="$root/.rorcc/runs/$run_id"
  meta="$run_dir/metadata.tsv"
  [ -f "$meta" ] && [ -f "$run_dir/state.tsv" ] || {
    err "run is not resumable: $run_id"
    return 1
  }

  workflow="$(_run_meta_get "$meta" workflow)"
  [ -n "$workflow" ] || { err "run metadata is missing workflow"; return 1; }
  wf="$root/.ai/workflows/$workflow.yaml"
  [ -f "$wf" ] || { err "workflow no longer exists: $workflow"; return 1; }

  _resume_validate "$root" "$wf" "$meta" "$force" || return 1

  classified="$(_run_meta_get "$meta" classified)"
  size="$(_run_meta_get "$meta" size)"
  signals="$(_run_meta_get "$meta" signals)"
  only="$(_run_meta_get "$meta" only)"
  skip="$(_run_meta_get "$meta" skip)"
  full="$(_run_meta_get "$meta" full)"
  auto="$(_run_meta_get "$meta" auto)"
  backend="$(_run_meta_get "$meta" backend)"

  args=("$workflow" "--resume-run" "$run_id")
  if [ "$classified" = "1" ] && [ -n "$size" ]; then
    args+=("--size" "$size")
    [ -n "$signals" ] && args+=("--signals" "$signals")
  fi
  [ -n "$only" ] && args+=("--only" "$only")
  [ -n "$skip" ] && args+=("--skip" "$skip")
  [ "$full" = "1" ] && args+=("--full")

  if [ "$auto_override" = "1" ] || { [ -z "$auto_override" ] && [ "$auto" = "1" ]; }; then
    args+=("--auto")
  fi

  [ -n "$backend_override" ] && backend="$backend_override"
  case "$backend" in
    cloud) args+=("--cloud") ;;
    local) args+=("--local") ;;
  esac

  info "resuming workflow '$workflow' from run $run_id"
  cmd_workflow "${args[@]}"
}
