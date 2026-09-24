# shellcheck shell=bash
# Stack id for the path router. Phase 5. Does not change which units are selected.
# See docs/architecture/adr-0010-stack-core.md.

# _stack_id <project-root>
_stack_id() {
  local root="$1"
  if [ -f "$root/Gemfile" ] || [ -f "$root/config/application.rb" ] || [ -f "$root/bin/rails" ]; then
    printf '%s\n' rails
    return 0
  fi
  printf '%s\n' unspecified
}
