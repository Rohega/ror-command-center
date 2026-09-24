# shellcheck shell=bash
# rorcc actions — phase 2. file/shell on the project tree, git as the undo.
# See docs/architecture/adr-0007-action-runner.md.

_actions_safe_path() {
  case "$1" in
    ""|/*|..|../*|*/../*|*/..) return 1 ;;
  esac
  return 0
}

_actions_checkpoint() {
  local index tree parent
  ACTIONS_HEAD="$(git rev-parse HEAD)" || return 1
  index="$(mktemp)"
  GIT_INDEX_FILE="$index" git read-tree HEAD || { rm -f "$index"; return 1; }
  GIT_INDEX_FILE="$index" git add -A || { rm -f "$index"; return 1; }
  tree="$(GIT_INDEX_FILE="$index" git write-tree)" || { rm -f "$index"; return 1; }
  rm -f "$index"
  parent="$ACTIONS_HEAD"
  ACTIONS_CHECKPOINT="$(
    GIT_AUTHOR_NAME=rorcc GIT_AUTHOR_EMAIL=rorcc@localhost \
    GIT_COMMITTER_NAME=rorcc GIT_COMMITTER_EMAIL=rorcc@localhost \
    git commit-tree "$tree" -p "$parent" -m "rorcc checkpoint"
  )" || return 1
  git update-ref refs/rorcc/checkpoint "$ACTIONS_CHECKPOINT"
}

_actions_restore() {
  [ "$(git rev-parse HEAD)" = "$ACTIONS_HEAD" ] || git reset --mixed "$ACTIONS_HEAD"
  git read-tree -u --reset "$ACTIONS_CHECKPOINT"
  git clean -fd
  git reset --mixed "$ACTIONS_HEAD"
}

_actions_fail() {
  local kind="$1" label="$2"
  printf 'failed %s %s\n' "$kind" "$label"
  _actions_restore
  return 1
}

_actions_apply() {
  local kind="$1" label="$2" body="$3" dir
  printf 'pending %s %s\n' "$kind" "$label"
  printf 'running %s %s\n' "$kind" "$label"
  case "$kind" in
    file)
      dir="$(dirname "$label")"
      [ "$dir" = "." ] || mkdir -p "$dir"
      printf '%s' "$body" >"$label" || { _actions_fail file "$label"; return 1; }
      ;;
    shell)
      bash -c "$label" || { _actions_fail shell "$label"; return 1; }
      ;;
    *) err "unknown action: $kind"; return 2 ;;
  esac
  printf 'complete %s %s\n' "$kind" "$label"
}

cmd_actions() {
  local undo=0 list=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --undo) undo=1 ;;
      -*) err "unknown option: $1"; return 2 ;;
      *)
        [ -z "$list" ] || { err "unexpected argument: $1"; return 2; }
        list="$1"
        ;;
    esac
    shift
  done

  local root; root="$(find_ai_root)" || { err "no .ai/ framework found — run this inside your project folder."; return 1; }
  case "$PWD/" in
    "$root"/*|"$root/") ;;
    *) err "run actions inside the project that contains .ai/"; return 1 ;;
  esac
  cd "$root" || return 1
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { err "actions need a git repository"; return 1; }
  git rev-parse --verify HEAD >/dev/null 2>&1 || { err "actions need at least one commit"; return 1; }

  if [ "$undo" -eq 1 ]; then
    git rev-parse --verify refs/rorcc/checkpoint >/dev/null 2>&1 || { err "no checkpoint to undo"; return 1; }
    ACTIONS_HEAD="$(git rev-parse HEAD)"
    ACTIONS_CHECKPOINT="$(git rev-parse refs/rorcc/checkpoint)"
    _actions_restore
    ok "restored $ACTIONS_CHECKPOINT"
    return 0
  fi

  [ -n "$list" ] && [ -f "$list" ] || { err "usage: rorcc actions <file>|--undo"; return 2; }

  local line kind="" label="" body="" started=0
  local -a kinds=() labels=() bodies=()
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "--- file "*)
        if [ "$started" -eq 1 ]; then kinds+=("$kind"); labels+=("$label"); bodies+=("$body"); fi
        kind="file"; label="${line#--- file }"; body=""; started=1
        _actions_safe_path "$label" || { err "refusing path: $label"; return 1; }
        ;;
      "--- shell "*)
        if [ "$started" -eq 1 ]; then kinds+=("$kind"); labels+=("$label"); bodies+=("$body"); fi
        kind="shell"; label="${line#--- shell }"; body=""; started=1
        ;;
      *)
        [ "$started" -eq 1 ] || { err "action list must start with --- file or --- shell"; return 2; }
        body="${body}${line}"$'\n'
        ;;
    esac
  done <"$list"
  [ "$started" -eq 1 ] || { err "action list is empty"; return 2; }
  kinds+=("$kind"); labels+=("$label"); bodies+=("$body")

  _actions_checkpoint || { err "could not write the git checkpoint"; return 1; }
  local i
  for i in "${!kinds[@]}"; do
    _actions_apply "${kinds[$i]}" "${labels[$i]}" "${bodies[$i]}" || return 1
  done
}
