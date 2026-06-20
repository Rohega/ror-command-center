#!/usr/bin/env bash
# RoR Command Center — installer
# Copies the framework core into a target project without example-specific content.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR"

# --- Defaults -----------------------------------------------------------------
FORCE=0
DRY_RUN=0
BACKUP=0
WITH_EXAMPLES=0
INSTALL_CLI=0
TARGET=""

# Counters
COUNT_COPIED=0
COUNT_SKIPPED=0
COUNT_CREATED=0

# --- Colors (disabled when not a TTY) -----------------------------------------
if [ -t 1 ]; then
  C_RESET="\033[0m"; C_DIM="\033[2m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_BLUE="\033[34m"; C_RED="\033[31m"; C_BOLD="\033[1m"
else
  C_RESET=""; C_DIM=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RED=""; C_BOLD=""
fi

# --- Framework core (generic, reusable) ---------------------------------------
# Files and directories copied as-is into the target project.
CORE_ITEMS=(
  ".ai"
  ".cursor"
  ".claude/agents"
  ".claude/hooks"
  ".claude/skills"
  ".claude/settings.json"
  "CLAUDE.md"
  "docs/integrations"
  "docs/CLAUDE.md"
  "docs/COLLABORATIVE-DESIGN-PRINCIPLE.md"
  ".github/copilot-instructions.md"
)

# Empty docs scaffolding (created with a .gitkeep, no example content).
SCAFFOLD_DIRS=(
  "docs/architecture"
  "docs/specs"
  "docs/stories"
  "docs/design"
  "docs/runbooks"
  "docs/modules"
)

# Extra items copied only with --with-examples.
EXAMPLE_ITEMS=(
  "examples"
  "docs/architecture"
  "docs/specs"
  "docs/stories"
  "docs/design"
  "docs/runbooks"
)

usage() {
  cat <<'EOF'
RoR Command Center — installer

USAGE:
  ./install.sh [options] <target-dir>

ARGUMENTS:
  <target-dir>      Path to the project where the framework will be installed.
                    Created if it does not exist.

OPTIONS:
  --force           Overwrite files that already exist in the target.
  --dry-run         Show what would happen without writing anything.
  --backup          Back up conflicting files to <file>.bak before overwriting.
  --with-examples   Also copy example content (examples/ and warehouse docs).
  --install-cli     Link the 'rorcc' CLI into your PATH (for local Ollama use)
                    and exit. No <target-dir> required.
  -h, --help        Show this help.

WHAT GETS COPIED (core):
  .ai/  .cursor/  .claude/{agents,hooks,skills,settings.json}
  CLAUDE.md  docs/integrations/  docs/CLAUDE.md
  docs/COLLABORATIVE-DESIGN-PRINCIPLE.md
  .github/copilot-instructions.md
  + empty docs/ scaffolding (architecture, specs, stories, design, runbooks, modules)

WHAT IS EXCLUDED:
  examples/, archive/, production/, .git/, repo meta files, and warehouse-mvp
  example docs (unless --with-examples is passed).

EXAMPLES:
  ./install.sh ../my-rails-app
  ./install.sh --dry-run /tmp/test-rolos
  ./install.sh --force --backup ~/projects/my-app
EOF
}

log()  { printf '%b\n' "$1"; }
info() { printf '%b\n' "${C_BLUE}==>${C_RESET} $1"; }
warn() { printf '%b\n' "${C_YELLOW}!${C_RESET} $1"; }
err()  { printf '%b\n' "${C_RED}error:${C_RESET} $1" >&2; }

# --- Parse args ---------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --backup) BACKUP=1 ;;
    --with-examples) WITH_EXAMPLES=1 ;;
    --install-cli) INSTALL_CLI=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) err "unknown option: $1"; echo; usage; exit 2 ;;
    *)
      if [ -n "$TARGET" ]; then
        err "unexpected extra argument: $1"; exit 2
      fi
      TARGET="$1"
      ;;
  esac
  shift
done

# --- Optional: link the rorcc CLI into PATH ----------------------------------
install_cli() {
  local cli="$SRC/cli/rorcc"
  if [ ! -f "$cli" ]; then
    err "CLI not found at $cli"; exit 1
  fi
  chmod +x "$cli" 2>/dev/null || true

  local bindir=""
  for d in "$HOME/.local/bin" "/usr/local/bin"; do
    if [ -d "$d" ] && [ -w "$d" ]; then bindir="$d"; break; fi
  done
  if [ -z "$bindir" ]; then
    bindir="$HOME/.local/bin"
    mkdir -p "$bindir"
  fi

  ln -sf "$cli" "$bindir/rorcc"
  info "Linked rorcc → ${C_DIM}$bindir/rorcc${C_RESET}"
  case ":$PATH:" in
    *":$bindir:"*) log "  ${C_GREEN}rorcc${C_RESET} is on your PATH. Try: rorcc doctor" ;;
    *) warn "add $bindir to your PATH, then run: rorcc doctor" ;;
  esac
}

if [ "$INSTALL_CLI" -eq 1 ]; then
  log "${C_BOLD}RoR Command Center — CLI install${C_RESET}"
  install_cli
  exit 0
fi

if [ -z "$TARGET" ]; then
  err "missing <target-dir>"; echo; usage; exit 2
fi

# --- Validate target ----------------------------------------------------------
mkdir -p "$TARGET" 2>/dev/null || true
if [ ! -d "$TARGET" ]; then
  err "could not create target directory: $TARGET"; exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$SRC" ]; then
  err "target directory is the framework repo itself; choose a different destination."; exit 1
fi

# --- Copy helpers -------------------------------------------------------------
# Copy a single file, honoring FORCE/BACKUP/DRY_RUN.
copy_file() {
  local rel="$1"
  local src="$SRC/$rel"
  local dst="$TARGET/$rel"

  if [ -e "$dst" ] && [ "$FORCE" -ne 1 ]; then
    log "  ${C_DIM}skip${C_RESET}  $rel ${C_DIM}(exists)${C_RESET}"
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "  ${C_GREEN}copy${C_RESET}  $rel"
    COUNT_COPIED=$((COUNT_COPIED + 1))
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ "$BACKUP" -eq 1 ]; then
    cp -p "$dst" "$dst.bak"
  fi
  cp -p "$src" "$dst"
  log "  ${C_GREEN}copy${C_RESET}  $rel"
  COUNT_COPIED=$((COUNT_COPIED + 1))
}

# Recursively copy a directory file-by-file so per-file rules apply.
copy_dir() {
  local rel="$1"
  local src="$SRC/$rel"
  [ -d "$src" ] || return 0

  local f relf
  while IFS= read -r -d '' f; do
    relf="${f#"$SRC"/}"
    copy_file "$relf"
  done < <(find "$src" -type f -print0)
}

# Copy a path that may be a file or directory.
copy_item() {
  local rel="$1"
  if [ -d "$SRC/$rel" ]; then
    copy_dir "$rel"
  elif [ -f "$SRC/$rel" ]; then
    copy_file "$rel"
  else
    warn "source not found, skipping: $rel"
  fi
}

# Create an empty scaffolding dir with a .gitkeep.
scaffold_dir() {
  local rel="$1"
  local dst="$TARGET/$rel"
  local keep="$dst/.gitkeep"

  if [ -d "$dst" ]; then
    log "  ${C_DIM}skip${C_RESET}  $rel/ ${C_DIM}(exists)${C_RESET}"
    COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
    return
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    log "  ${C_BLUE}mkdir${C_RESET} $rel/"
    COUNT_CREATED=$((COUNT_CREATED + 1))
    return
  fi

  mkdir -p "$dst"
  : > "$keep"
  log "  ${C_BLUE}mkdir${C_RESET} $rel/"
  COUNT_CREATED=$((COUNT_CREATED + 1))
}

# --- Run ----------------------------------------------------------------------
log "${C_BOLD}RoR Command Center — installer${C_RESET}"
log "  source: ${C_DIM}$SRC${C_RESET}"
log "  target: ${C_DIM}$TARGET${C_RESET}"
[ "$DRY_RUN" -eq 1 ] && warn "dry-run: no files will be written"
[ "$FORCE" -eq 1 ] && warn "force: existing files will be overwritten"
log ""

info "Copying framework core"
for item in "${CORE_ITEMS[@]}"; do
  copy_item "$item"
done

log ""
info "Creating docs scaffolding"
for d in "${SCAFFOLD_DIRS[@]}"; do
  scaffold_dir "$d"
done

if [ "$WITH_EXAMPLES" -eq 1 ]; then
  log ""
  info "Copying example content (--with-examples)"
  for item in "${EXAMPLE_ITEMS[@]}"; do
    copy_item "$item"
  done
fi

# --- Summary ------------------------------------------------------------------
log ""
log "${C_BOLD}Summary${C_RESET}"
log "  ${C_GREEN}copied:${C_RESET}  $COUNT_COPIED"
log "  ${C_BLUE}created:${C_RESET} $COUNT_CREATED"
log "  ${C_DIM}skipped:${C_RESET} $COUNT_SKIPPED"

if [ "$DRY_RUN" -eq 1 ]; then
  log ""
  warn "dry-run complete — re-run without --dry-run to apply."
else
  log ""
  log "${C_GREEN}Done.${C_RESET} Next steps:"
  log "  1. cd $TARGET"
  log "  2. Open in Cursor (rules in .cursor/rules/ load automatically) or run 'claude'."
  log "  3. See docs/integrations/ for your AI platform setup."
fi
